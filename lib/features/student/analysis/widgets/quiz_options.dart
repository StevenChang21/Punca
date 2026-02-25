import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/widgets/math_display.dart';

class QuizOptions extends StatelessWidget {
  final List<String> options;
  final String? selectedOption;
  final String correctAnswer;
  final bool isAnswered;
  final bool isLoading;
  final int level;
  final int viewingLevel;
  final ValueChanged<String> onOptionSelect;
  final VoidCallback onChallenge;
  final VoidCallback onDone;
  final bool hideActionButtons;

  const QuizOptions({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.correctAnswer,
    required this.isAnswered,
    required this.isLoading,
    required this.level,
    required this.viewingLevel,
    required this.onOptionSelect,
    required this.onChallenge,
    required this.onDone,
    this.hideActionButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...options.map((option) {
          final isSelected = selectedOption == option;
          final isCorrectAnswer = option == correctAnswer;

          Color bgColor = Colors.transparent;
          Color borderColor = Colors.grey.shade300;
          Color textColor = Colors.black87;
          IconData? icon;
          Color iconColor = Colors.transparent;

          if (isAnswered) {
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
              onTap: () => onOptionSelect(option),
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
                      child: MixedMathText(
                        content: option,
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight:
                              (isSelected || (isAnswered && isCorrectAnswer))
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

        if (selectedOption != null && !isAnswered && !isLoading)
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

        if (!hideActionButtons) ...[
          // Action Buttons
          if (isAnswered && level < 2 && !isLoading && viewingLevel == level)
            ElevatedButton.icon(
              onPressed: onChallenge,
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

          if ((isAnswered && level == 2) || (isAnswered && isLoading))
            ElevatedButton(
              onPressed: onDone,
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
    );
  }
}
