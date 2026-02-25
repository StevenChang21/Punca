import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/widgets/math_display.dart';

class LessonSection extends StatelessWidget {
  final List<String> lessonChunks;
  final int visibleChunkCount;
  final bool isLessonComplete;
  final bool practiceStarted;
  final VoidCallback onShowNextChunk;
  final VoidCallback onStartPractice;
  final bool isLoading;

  const LessonSection({
    super.key,
    required this.lessonChunks,
    required this.visibleChunkCount,
    required this.isLessonComplete,
    required this.practiceStarted,
    required this.onShowNextChunk,
    required this.onStartPractice,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (lessonChunks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(visibleChunkCount, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < visibleChunkCount - 1 ? 16.0 : 0,
                ),
                child: MixedMathText(
                  content: lessonChunks[index],
                  textStyle: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons
        if (!isLessonComplete) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onShowNextChunk,
              icon: const Icon(Icons.arrow_downward),
              label: const Text("Continue Learning"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onStartPractice,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Skip to Practice",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ] else if (!practiceStarted) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onStartPractice,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(isLoading ? "Loading..." : "Start Practice"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
