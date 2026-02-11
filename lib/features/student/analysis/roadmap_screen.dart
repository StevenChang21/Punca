import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class RoadmapScreen extends StatelessWidget {
  final List<dynamic> roadmapData;

  const RoadmapScreen({super.key, required this.roadmapData});

  @override
  Widget build(BuildContext context) {
    // HARDCODED MOCK DATA: Targeted Remediation for "Linear Equations"
    final steps = [
      {
        "title": "Algebra Basics",
        "level": "Standard 6",
        "status": "completed",
        "desc": "Understanding variables and basic operations.",
      },
      {
        "title": "Algebraic Expressions",
        "level": "Form 1 · Chapter 5",
        "status": "completed",
        "desc": "Simplifying expressions with coefficients.",
      },
      {
        "title": "Linear Equations I",
        "level": "Form 1 · Chapter 6",
        "status": "focus",
        "desc": "Solving basic linear equations with one variable.",
      },
      {
        "title": "Linear Equations II",
        "level": "Form 2 · Chapter 6",
        "status": "upcoming",
        "desc": "TARGET GOAL: Solving complex linear equations.",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey back for clean look
      appBar: AppBar(
        title: const Text(
          "Personalized Path",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Weakness Detected".toUpperCase(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Linear Equations",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We've built a targeted plan to help you master this concept, starting from the basics.",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "YOUR PATH TO MASTERY",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),

            // Steps
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isLast = index == steps.length - 1;
                return _buildStepItem(
                  context,
                  step,
                  isLast: isLast,
                  index: index + 1,
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    Map<String, dynamic> step, {
    required bool isLast,
    required int index,
  }) {
    final status = step['status'];
    final isCompleted = status == 'completed';
    final isFocus = status == 'focus';

    Color color;
    IconData icon;

    if (isCompleted) {
      color = Colors.green;
      icon = Icons.check;
    } else if (isFocus) {
      color = AppColors.primary;
      icon = Icons.play_arrow_rounded;
    } else {
      color = Colors.grey[400]!;
      icon =
          Icons.circle_outlined; // Or lock if locked, but user said not locked.
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green[100]
                      : (isFocus ? color : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : (isFocus ? color : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isCompleted
                      ? Colors.green[700]
                      : (isFocus ? Colors.white : Colors.grey[400]),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.green[200] : Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isFocus
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      step['level'],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isFocus ? AppColors.primary : Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['title'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isFocus
                          ? Colors.black
                          : (isCompleted ? Colors.grey[800] : Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['desc'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  if (isFocus) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_circle_outline, size: 16),
                        label: const Text("Start Lesson"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
