import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/services/gemini_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class RemediationSheet extends StatefulWidget {
  final RemediationDrill drill;
  final Weakness weakness;
  final VoidCallback onMorePractice;

  const RemediationSheet({
    super.key,
    required this.drill,
    required this.weakness,
    required this.onMorePractice,
  });

  @override
  State<RemediationSheet> createState() => _RemediationSheetState();
}

class _RemediationSheetState extends State<RemediationSheet> {
  late RemediationDrill _currentDrill;
  int _level = 0; // 0=Base, 1=Hard, 2=Hardest
  bool _isLoading = false;

  String? _selectedOption;
  bool _isAnswered =
      false; // True if the User has successfully found the Correct Answer

  List<String> _lessonChunks = [];
  int _visibleChunkCount = 0;

  @override
  void initState() {
    super.initState();
    _initDrill(widget.drill);
  }

  void _initDrill(RemediationDrill drill) {
    _currentDrill = drill;
    // Split by double newline to get paragraphs, filter empty ones
    _lessonChunks = drill.miniLesson
        .split(RegExp(r'\n\s*\n'))
        .where((chunk) => chunk.trim().isNotEmpty)
        .toList();
    // Start with 1 chunk visible, or all if empty (edge case)
    _visibleChunkCount = _lessonChunks.isNotEmpty ? 1 : 0;
  }

  void _handleOptionSelect(String option) {
    if (_isAnswered || _isLoading) return; // Lock interactions

    final isCorrect = option == _currentDrill.correctAnswer;

    setState(() {
      _selectedOption = option;
      if (isCorrect) {
        _isAnswered = true; // Lock session as "Success"
      }
      // If wrong, we just update _selectedOption to show Red,
      // but _isAnswered stays false so they can tap again.
    });
  }

  Future<void> _handleChallenge() async {
    setState(() => _isLoading = true);

    final nextLevel = _level + 1;
    final newDrill = await GeminiService().generateChallengeDrill(
      widget.weakness,
      _currentDrill,
      nextLevel,
    );

    if (mounted) {
      if (newDrill != null) {
        setState(() {
          _initDrill(newDrill);
          _level = nextLevel;
          _selectedOption = null;
          _isAnswered = false;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not generate challenge. Check internet!"),
          ),
        );
      }
    }
  }

  void _showNextChunk() {
    setState(() {
      if (_visibleChunkCount < _lessonChunks.length) {
        _visibleChunkCount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if lesson is fully revealed

    // DEV NOTE: Handle Hot Reload where initState is skipped
    if (_lessonChunks.isEmpty && widget.drill.miniLesson.isNotEmpty) {
      _initDrill(widget.drill);
    }

    final isLessonComplete = _visibleChunkCount == _lessonChunks.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title & Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _level > 0
                          ? Colors.orange.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _level == 0
                          ? "MINI LESSON"
                          : "LEVEL ${_level + 1} CHALLENGE",
                      style: TextStyle(
                        color: _level > 0 ? Colors.orange : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentDrill.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mini Lesson Text (Progressive)
              if (_lessonChunks.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < _visibleChunkCount; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(height: 1),
                          ),
                        MarkdownBody(
                          data: _lessonChunks[i],
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 20,
                              height: 1.5,
                              color: AppColors.textPrimary,
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      if (!isLessonComplete) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showNextChunk,
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text("Continue Learning"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Question Header (HIDDEN UNTIL LESSON COMPLETE)
              if (isLessonComplete) ...[
                Text(
                  _level == 0 ? "Quick Practice" : "Solve This (Harder!)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Question Body
                MarkdownBody(
                  data: _currentDrill.twinQuestion,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    strong: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // Options Grid
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ..._currentDrill.options.map((option) {
                    final isSelected = _selectedOption == option;
                    final isCorrectAnswer =
                        option == _currentDrill.correctAnswer;

                    Color bgColor = Colors.transparent;
                    Color borderColor = Colors.grey.shade300;
                    Color textColor = Colors.black87;
                    IconData? icon;
                    Color iconColor = Colors.transparent;

                    if (_isAnswered) {
                      if (isCorrectAnswer) {
                        bgColor = Colors.green.shade50;
                        borderColor = Colors.green;
                        textColor = Colors.green;
                        icon = Icons.check_circle;
                        iconColor = Colors.green;
                      }
                    } else if (isSelected) {
                      bgColor = Colors.red.shade50;
                      borderColor = Colors.red;
                      textColor = Colors.red;
                      icon = Icons.cancel;
                      iconColor = Colors.red;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _handleOptionSelect(option),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                    fontWeight:
                                        (isSelected ||
                                            (_isAnswered && isCorrectAnswer))
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (icon != null) Icon(icon, color: iconColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                if (_selectedOption != null && !_isAnswered && !_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: Text(
                        "Incorrect, Try Again!",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Action Buttons
                if (_isAnswered && _level < 2 && !_isLoading)
                  ElevatedButton.icon(
                    onPressed: _handleChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bolt),
                    label: const Text("Challenge Me! (Harder)"),
                  ),

                if ((_isAnswered && _level == 2) || (_isAnswered && _isLoading))
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Great Work! Done."),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
