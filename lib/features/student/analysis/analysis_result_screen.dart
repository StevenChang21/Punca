import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/roadmap_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'dart:io';

class AnalysisResultScreen extends StatelessWidget {
  final AssessmentResult result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
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
            _buildScoreCard(result.subject, result.grade),
            const SizedBox(height: 24),
            _buildConfidenceBuilder(result.confidenceBuilder),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Weakness Analysis",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (result.imageUrls.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(
                      Icons.collections,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      "View ${result.imageUrls.length > 1 ? 'Pages (${result.imageUrls.length})' : 'Page'}",
                    ),
                    onPressed: () => _showImages(context, result.imageUrls),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.weaknesses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No specific weaknesses identified! Great job!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...result.weaknesses.map((w) {
                return _buildWeaknessItem(context, w);
              }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Roadmap
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RoadmapScreen(roadmapData: result.remediationDrills),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "View Generated Roadmap",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(GapType type) {
    switch (type) {
      case GapType.foundation:
        return Colors.redAccent;
      case GapType.execution:
        return Colors.orangeAccent;
      case GapType.precision:
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  void _showImages(BuildContext context, List<String> paths) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Original Work (${paths.length} pages)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: paths.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(paths[index])),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String subject, String grade) {
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
                  subject,
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Paper Analysis",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
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

  Widget _buildWeaknessItem(BuildContext context, Weakness w) {
    final color = _getColorForType(w.gapType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 48,
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
                            w.topic,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (w.priority >= 8)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "CRITICAL",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Grade Gap: ${w.gapType.name.toUpperCase()}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (w.mistakeExample.isNotEmpty ||
              w.correctionExample.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (w.mistakeExample.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Step",
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            w.mistakeExample,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (w.mistakeExample.isNotEmpty &&
                    w.correctionExample.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                if (w.correctionExample.isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Correct Step",
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            w.correctionExample,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (w.syllabusRefs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: w.syllabusRefs.map((ref) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "Form ${ref.form} • Ch ${ref.chapterId}${ref.subtopicId != null ? ' • ${ref.subtopicId}' : ''}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: const Text(
                "See Explanation",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              children: [
                Text(
                  w.reason,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (w.action.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.action,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
