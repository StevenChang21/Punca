import 'package:flutter/material.dart';
import 'package:punca_ai/core/models/assignment_model.dart';
import 'package:punca_ai/core/models/assessment_model.dart'; // For RemediationDrill
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/widgets/lesson_section.dart';
import 'package:punca_ai/features/student/analysis/widgets/question_section.dart';
import 'package:punca_ai/features/student/analysis/widgets/quiz_options.dart';
import 'package:punca_ai/core/services/firebase_service.dart';

class AssignmentSolveScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentSolveScreen({super.key, required this.assignment});

  @override
  State<AssignmentSolveScreen> createState() => _AssignmentSolveScreenState();
}

class _AssignmentSolveScreenState extends State<AssignmentSolveScreen> {
  late RemediationDrill _drill;
  late List<String> _lessonChunks;
  int _visibleChunkCount = 1;
  bool _practiceStarted = false;

  bool _isAnswered = false;
  String? _selectedOption;
  bool _isSaving = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _drill = widget.assignment.remediationDrill;
    _lessonChunks = _drill.lessonChunks;
    if (_lessonChunks.isEmpty) {
      _visibleChunkCount = 0;
      _practiceStarted = true;
    }
  }

  void _showNextChunk() {
    setState(() {
      if (_visibleChunkCount < _lessonChunks.length) {
        _visibleChunkCount++;
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  void _handleOptionSelect(String option) {
    if (_isAnswered || _isSaving) return;
    final isCorrect = option == _drill.correctAnswer;
    setState(() {
      _selectedOption = option;
      if (isCorrect) {
        _isAnswered = true;
        _saveAssignmentCompleted();
      }
    });
  }

  Future<void> _saveAssignmentCompleted() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseService().updateAssignmentStatus(
        widget.assignment.id,
        'completed',
        100, // Hardcoded 100 for correct answer on first try
      );
    } catch (e) {
      debugPrint("Error saving assignment: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLessonComplete = _visibleChunkCount == _lessonChunks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.topic),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isAnswered)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Done",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // LessonSection
                  LessonSection(
                    lessonChunks: _lessonChunks,
                    visibleChunkCount: _visibleChunkCount,
                    isLessonComplete: isLessonComplete,
                    practiceStarted: _practiceStarted,
                    onShowNextChunk: _showNextChunk,
                    onStartPractice: () {
                      setState(() => _practiceStarted = true);
                      _scrollToBottom();
                    },
                    isLoading: false,
                  ),

                  if (_practiceStarted) ...[
                    const SizedBox(height: 32),
                    const Divider(color: AppColors.background),
                    const SizedBox(height: 32),

                    // Question Section
                    QuestionSection(
                      title: "Your Question",
                      question: _drill.twinQuestion,
                    ),
                    const SizedBox(height: 24),

                    // Options
                    QuizOptions(
                      options: _drill.options,
                      correctAnswer: _drill.correctAnswer,
                      selectedOption: _selectedOption,
                      isAnswered: _isAnswered,
                      isLoading: _isSaving,
                      level: 0,
                      viewingLevel: 0,
                      onOptionSelect: _handleOptionSelect,
                      onChallenge: () {}, // Not used here
                      onDone: () {}, // Handled manually below
                      hideActionButtons: true,
                    ),

                    if (_isAnswered) ...[
                      const SizedBox(height: 24),
                      // Success Message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Great job! Assignment completed.",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Return to Classroom",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 60),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
