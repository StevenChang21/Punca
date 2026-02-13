import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class GapAnalysisChart extends StatelessWidget {
  final double foundationPct; // Concept
  final double executionPct; // Process
  final double precisionPct; // Careless

  const GapAnalysisChart({
    super.key,
    required this.foundationPct,
    required this.executionPct,
    required this.precisionPct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Root Cause Analysis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              "Why asking for help?",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segmented Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                _buildSegment(foundationPct, Colors.redAccent, "Concept"),
                _buildSegment(executionPct, Colors.orangeAccent, "Process"),
                _buildSegment(precisionPct, Colors.blueAccent, "Careless"),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              "Concept",
              "${(foundationPct * 100).toInt()}%",
              Colors.redAccent,
            ),
            _buildLegendItem(
              "Process",
              "${(executionPct * 100).toInt()}%",
              Colors.orangeAccent,
            ),
            _buildLegendItem(
              "Careless",
              "${(precisionPct * 100).toInt()}%",
              Colors.blueAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegment(double flex, Color color, String label) {
    if (flex <= 0) return const SizedBox.shrink();
    return Expanded(
      flex: (flex * 100).toInt(),
      child: Container(color: color),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
