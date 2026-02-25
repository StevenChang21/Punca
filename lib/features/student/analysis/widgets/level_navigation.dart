import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class LevelNavigation extends StatelessWidget {
  final int historyLength;
  final int viewingLevel;
  final int currentLevel;
  final Map<int, bool> answeredLevels;
  final ValueChanged<int> onLevelSelect;

  const LevelNavigation({
    super.key,
    required this.historyLength,
    required this.viewingLevel,
    required this.currentLevel,
    required this.answeredLevels,
    required this.onLevelSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (historyLength <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(historyLength, (i) {
              final isViewing = viewingLevel == i;
              final isAnswered = answeredLevels[i] == true;
              final label = i == 0 ? 'Base' : 'Level $i';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      if (isAnswered) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                      ],
                    ],
                  ),
                  selected: isViewing,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  onSelected: (_) => onLevelSelect(i),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
