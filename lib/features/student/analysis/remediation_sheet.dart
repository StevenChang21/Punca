import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/services/gemini_service.dart';
import 'package:punca_ai/features/student/analysis/widgets/lesson_section.dart';
import 'package:punca_ai/features/student/analysis/widgets/question_section.dart';
import 'package:punca_ai/features/student/analysis/widgets/quiz_options.dart';
import 'package:punca_ai/features/student/analysis/widgets/level_navigation.dart';

class RemediationSheet extends StatefulWidget {
  final RemediationDrill drill;
  final Weakness weakness;
  final VoidCallback onMorePractice;
  final ValueChanged<List<RemediationDrill>>? onDrillUpdated;
  final List<RemediationDrill> drillHistory;

  const RemediationSheet({
    super.key,
    required this.drill,
    required this.weakness,
    required this.onMorePractice,
    this.onDrillUpdated,
    this.drillHistory = const [],
  });

  @override
  State<RemediationSheet> createState() => _RemediationSheetState();
}

class _RemediationSheetState extends State<RemediationSheet> {
  late RemediationDrill _currentDrill;
  int _level = 0; // 0=Base, 1=Hard, 2=Hardest
  int _viewingLevel = 0; // Which level the student is currently viewing
  bool _isLoading = false;

  String? _selectedOption;
  bool _isAnswered =
      false; // True if the User has successfully found the Correct Answer

  // History of all drills (index = level)
  final List<RemediationDrill> _drillHistory = [];
  // Track answer state per level
  final Map<int, String?> _selectedOptions = {};
  final Map<int, bool> _answeredLevels = {};

  List<String> _lessonChunks = [];
  int _visibleChunkCount = 0;
  bool _practiceStarted = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load history from parent (persisted drills)
    if (widget.drillHistory.isNotEmpty) {
      _drillHistory.addAll(widget.drillHistory);
      final lastDrill = _drillHistory.last;
      _initDrill(lastDrill);
      _level = _drillHistory.length - 1;
      _viewingLevel = _level;
      // Mark all past levels as answered (they were completed before)
      for (int i = 0; i < _drillHistory.length - 1; i++) {
        _answeredLevels[i] = true;
      }
    } else {
      _initDrill(widget.drill);
      _drillHistory.add(widget.drill);
    }
  }

  void _initDrill(RemediationDrill drill) {
    _currentDrill = drill;
    _lessonChunks = _currentDrill.lessonChunks;

    // Start with 1 chunk visible, or all if empty (edge case)
    _visibleChunkCount = _lessonChunks.isNotEmpty ? 1 : 0;
    _practiceStarted = false;

    // Reset scroll to top when initializing new drill
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _handleOptionSelect(String option) {
    if (_isAnswered || _isLoading) return;
    if (_viewingLevel != _level) return; // Can't answer past questions

    final isCorrect = option == _currentDrill.correctAnswer;

    setState(() {
      _selectedOption = option;
      _selectedOptions[_viewingLevel] = option;
      if (isCorrect) {
        _isAnswered = true;
        _answeredLevels[_viewingLevel] = true;
      }
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
        // Always preserve the ORIGINAL (base) mini lesson and vocabulary
        final baseDrill = _drillHistory[0];
        final hybridDrill = RemediationDrill(
          title: newDrill.title,
          miniLesson: baseDrill.miniLesson,
          twinQuestion: newDrill.twinQuestion,
          correctAnswer: newDrill.correctAnswer,
          options: newDrill.options,
          vocabularyBridge: baseDrill.vocabularyBridge,
          weaknessId: baseDrill.weaknessId,
        );

        setState(() {
          // Swap drill but keep lesson visibility intact
          _currentDrill = hybridDrill;
          _drillHistory.add(hybridDrill);
          _level = nextLevel;
          _viewingLevel = nextLevel;
          _selectedOption = null;
          _isAnswered = false;
          _isLoading = false;
        });

        // Persist the full drill history
        widget.onDrillUpdated?.call(List.from(_drillHistory));

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
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

    // Auto-scroll to the bottom so the user can see the new chunk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _switchToLevel(int level) {
    if (level < 0 || level >= _drillHistory.length) return;
    setState(() {
      _viewingLevel = level;
      _currentDrill = _drillHistory[level];
      _selectedOption = _selectedOptions[level];
      _isAnswered = _answeredLevels[level] == true;
    });
  }

  Future<void> _handleRegenerateLesson() async {
    setState(() => _isLoading = true);

    // Scroll to top to show loading state
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    try {
      final newDrill = await GeminiService().generateRemediation(
        widget.weakness,
      );

      if (mounted) {
        if (newDrill != null) {
          setState(() {
            _drillHistory.clear();
            _drillHistory.add(newDrill);
            _initDrill(newDrill);
            _level = 0;
            _viewingLevel = 0;
            _selectedOption = null;
            _isAnswered = false;
            _selectedOptions.clear();
            _answeredLevels.clear();
            _isLoading = false;
          });

          // Persist regenerated drill to Firestore
          widget.onDrillUpdated?.call(List.from(_drillHistory));
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to regenerate lesson.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
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
          controller: _scrollController,
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

                  if (_level == 0) // Only allow regenerating the base lesson
                    IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, color: Colors.grey),
                      onPressed: _isLoading ? null : _handleRegenerateLesson,
                      tooltip: "Regenerate Lesson",
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Mini Lesson (Progressive)
              LessonSection(
                lessonChunks: _lessonChunks,
                visibleChunkCount: _visibleChunkCount,
                isLessonComplete: isLessonComplete,
                practiceStarted: _practiceStarted,
                onShowNextChunk: _showNextChunk,
                onStartPractice: () {
                  setState(() => _practiceStarted = true);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                },
                isLoading: _isLoading,
              ),

              if (_lessonChunks.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],

              // Practice Content
              if (_practiceStarted) ...[
                LevelNavigation(
                  historyLength: _drillHistory.length,
                  viewingLevel: _viewingLevel,
                  currentLevel: _level,
                  answeredLevels: _answeredLevels,
                  onLevelSelect: _switchToLevel,
                ),

                QuestionSection(
                  title: _viewingLevel == 0
                      ? 'Quick Practice'
                      : (_viewingLevel == _level
                            ? 'Solve This (Harder!)'
                            : 'Past Question (Level $_viewingLevel)'),
                  question: _currentDrill.twinQuestion,
                ),

                QuizOptions(
                  options: _currentDrill.options,
                  selectedOption: _selectedOption,
                  correctAnswer: _currentDrill.correctAnswer,
                  isAnswered: _isAnswered,
                  isLoading: _isLoading,
                  level: _level,
                  viewingLevel: _viewingLevel,
                  onOptionSelect: _handleOptionSelect,
                  onChallenge: _handleChallenge,
                  onDone: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
