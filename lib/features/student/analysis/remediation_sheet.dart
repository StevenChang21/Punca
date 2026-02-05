import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/services/gemini_service.dart';

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

  @override
  void initState() {
    super.initState();
    _currentDrill = widget.drill;
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
          _currentDrill = newDrill;
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

  @override
  Widget build(BuildContext context) {
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

              // Mini Lesson Text
              if (_currentDrill.miniLesson.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _currentDrill.miniLesson,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontFamily:
                          'Courier', // Monospace for ascii art alignment
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Question Header
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
              Text(
                _currentDrill.twinQuestion,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
                  final isCorrectAnswer = option == _currentDrill.correctAnswer;

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
          ),
        ),
      ),
    );
  }
}
