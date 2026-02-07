import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/models/assessment_model.dart';

class RemediationScreen extends StatefulWidget {
  final List<RemediationDrill> drills;

  const RemediationScreen({super.key, required this.drills});

  @override
  State<RemediationScreen> createState() => _RemediationScreenState();
}

class _RemediationScreenState extends State<RemediationScreen> {
  // Phase 1: Study Mode (Lessons)
  // Phase 2: Test Mode (Quizzes)
  bool _isTestMode = false;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late List<RemediationDrill> _shuffledQuizzes;

  @override
  void initState() {
    super.initState();
    // Create a shuffled copy of drills for the test phase to reduce predictability
    _shuffledQuizzes = List.from(widget.drills)..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.drills.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Remediation")),
        body: const Center(child: Text("No drills available.")),
      );
    }

    final currentList = _isTestMode ? _shuffledQuizzes : widget.drills;
    final progressLabel = _isTestMode
        ? "Quiz ${_currentIndex + 1} of ${currentList.length}"
        : "Lesson ${_currentIndex + 1} of ${currentList.length}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(progressLabel),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isTestMode)
            TextButton(
              onPressed: _startTestMode,
              child: const Text(
                "Skip to Quiz",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Force manual navigation
        itemCount: currentList.length,
        itemBuilder: (context, index) {
          if (_isTestMode) {
            return _QuizCard(
              drill: currentList[index],
              onComplete: () => _nextStep(currentList.length),
            );
          } else {
            return _LessonCard(
              drill: currentList[index],
              onComplete: () => _nextStep(currentList.length),
              isLast: index == currentList.length - 1,
            );
          }
        },
      ),
    );
  }

  void _nextStep(int totalLength) {
    if (_currentIndex < totalLength - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentIndex++;
      });
    } else {
      if (!_isTestMode) {
        // Finished Lessons -> Start Test
        _startTestMode();
      } else {
        // Finished Test -> Done
        Navigator.pop(context);
        _showCompletionDialog();
      }
    }
  }

  void _startTestMode() {
    setState(() {
      _isTestMode = true;
      _currentIndex = 0;
      _pageController.jumpToPage(0);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Study complete! Starting shuffled quizzes..."),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Great Job!"),
        content: const Text(
          "You've completed the active remediation cycle. Keep practicing!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Finish"),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final RemediationDrill drill;
  final VoidCallback onComplete;
  final bool isLast;

  const _LessonCard({
    required this.drill,
    required this.onComplete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            drill.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              drill.miniLesson,
              style: const TextStyle(fontSize: 18, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                isLast ? "I'm Ready for the Test" : "Next Lesson",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _QuizCard extends StatefulWidget {
  final RemediationDrill drill;
  final VoidCallback onComplete;

  const _QuizCard({required this.drill, required this.onComplete});

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  final TextEditingController _answerController = TextEditingController();
  bool _isWrong = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final drill = widget.drill;
    final List<String> options = drill.options;
    final bool isMCQ = options.isNotEmpty;

    if (_isCorrect) {
      return _buildSuccessView();
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Challenge",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              drill.twinQuestion,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          if (isMCQ)
            ...options.map(
              (opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: () => _checkAnswer(drill, opt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    elevation: 0,
                  ),
                  child: Text(opt, style: const TextStyle(fontSize: 16)),
                ),
              ),
            )
          else
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: "Enter your answer...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),

          if (_isWrong)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                "Not quite. Try again.",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Spacer(),
          if (!isMCQ)
            ElevatedButton(
              onPressed: () => _checkAnswer(drill, _answerController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Text(
                  "Submit Answer",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _checkAnswer(RemediationDrill drill, String userAnswer) {
    final correct = drill.correctAnswer.trim().toLowerCase();
    final user = userAnswer.trim().toLowerCase();

    // Fuzzy equality check
    if (user == correct || user.contains(correct)) {
      setState(() {
        _isCorrect = true;
        _isWrong = false;
      });
    } else {
      setState(() {
        _isWrong = true;
      });
    }
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 96, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          "Correct!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "You've mastered this concept.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: widget.onComplete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Next Challenge",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
