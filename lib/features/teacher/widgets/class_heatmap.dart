import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class ClassHeatmap extends StatelessWidget {
  const ClassHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data: Chapter -> Class Average
    final Map<String, double> classData = {
      "F2 C01: Patterns & Sequences": 0.82,
      "F2 C02: Factorisation": 0.65,
      "F2 C03: Algebraic Formulae": 0.45, // Alert!
      "F2 C04: Polygons": 0.78,
      "F2 C05: Circles": 0.55,
      "F2 C06: 3D Geo": 0.88,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Class Heatmap",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("View Full Syllabus"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: classData.length,
          itemBuilder: (context, index) {
            final key = classData.keys.elementAt(index);
            final score = classData[key]!;
            return _buildHeatmapTile(key, score);
          },
        ),
      ],
    );
  }

  Widget _buildHeatmapTile(String title, double score) {
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.split(':').last.trim(), // Show only topic name
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
                Text(
                  "Avg: ${(score * 100).toInt()}%",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
