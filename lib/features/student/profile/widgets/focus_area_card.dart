import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class FocusAreaCard extends StatelessWidget {
  final Map<String, double> masteryData;

  const FocusAreaCard({super.key, required this.masteryData});

  @override
  Widget build(BuildContext context) {
    if (masteryData.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Find topic with lowest mastery
    var lowestTopic = masteryData.keys.first;
    var lowestScore = masteryData[lowestTopic]!;

    masteryData.forEach((topic, score) {
      if (score < lowestScore) {
        lowestScore = score;
        lowestTopic = topic;
      }
    });

    // If everything is perfect, show a different message?
    // For now, simple logic: show lowest.

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt, // Lightning/Focus
                      color: Colors.yellowAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Current Focus",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                lowestTopic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Mastery Level: ${(lowestScore * 100).toInt()}%",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to remediation or specific drill
                    // For MVP, maybe show a toast or navigation placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Starting practice for $lowestTopic!"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  child: const Text("Improve This Score"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
