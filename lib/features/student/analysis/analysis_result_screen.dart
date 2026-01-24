import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/roadmap_screen.dart';

import 'dart:io';

class AnalysisResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final String? imagePath;

  const AnalysisResultScreen({super.key, required this.result, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> weaknesses = result['weaknesses'] ?? [];
    final String confidenceBuilder =
        result['confidence_builder'] ?? "Great effort! Keep practicing.";
    final String grade = result['grade'] ?? "N/A";
    final String subject = result['subject'] ?? "Math";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analysis Result"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(grade, subject),
            const SizedBox(height: 24),
            _buildConfidenceBuilder(confidenceBuilder),
            const SizedBox(height: 24),
            const Text(
              "Weakness Analysis (Tap to view)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (weaknesses.isEmpty)
              const Text("No specific weaknesses identified! Great job!")
            else
              ...weaknesses.map(
                (w) => _buildWeaknessItem(
                  context,
                  w['topic'] ?? 'Unknown',
                  w['reason'] ?? 'Needs review',
                  Colors.redAccent,
                  w['bounding_box'],
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RoadmapScreen(roadmapData: result['roadmap'] ?? []),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text("View Generated Roadmap"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String grade, String subject) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$subject - Assessment",
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Paper Analysis",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            grade,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBuilder(String message) {
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
          Text(message, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildWeaknessItem(
    BuildContext context,
    String topic,
    String reason,
    Color color,
    dynamic boundingBox,
  ) {
    return GestureDetector(
      onTap: () {
        if (imagePath != null &&
            boundingBox != null &&
            boundingBox is List &&
            boundingBox.length == 4) {
          _showMistakeOnImage(context, topic, boundingBox.cast<int>());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No location data for this issue.")),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: Colors.grey,
                      ), // Hint to tap
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showMistakeOnImage(BuildContext context, String label, List<int> box) {
    // Box is [ymin, xmin, ymax, xmax] 0-1000
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  foregroundPainter: BoundingBoxPainter(box, label),
                  child: Image.file(File(imagePath!)),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<int> box; // [ymin, xmin, ymax, xmax]
  final String label;

  BoundingBoxPainter(this.box, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Convert 0-1000 scale to pixel coordinates
    // box: [ymin, xmin, ymax, xmax]
    final double ymin = (box[0] / 1000) * size.height;
    final double xmin = (box[1] / 1000) * size.width;
    final double ymax = (box[2] / 1000) * size.height;
    final double xmax = (box[3] / 1000) * size.width;

    final rect = Rect.fromLTRB(xmin, ymin, xmax, ymax);
    canvas.drawRect(rect, paint);

    // Draw label background
    final textSpan = TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      xmin,
      ymin - textPainter.height - 4,
      textPainter.width + 16,
      textPainter.height + 4,
    );

    canvas.drawRect(labelRect, Paint()..color = Colors.red);

    textPainter.paint(canvas, Offset(xmin + 8, ymin - textPainter.height - 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
