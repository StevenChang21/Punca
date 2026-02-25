import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/widgets/math_display.dart';

class ConfidenceCard extends StatelessWidget {
  final String message;

  const ConfidenceCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                "Confidence Check",
                style: TextStyle(
                  color: AppColors.accent.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MixedMathText(
            content: message,
            textStyle: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}
