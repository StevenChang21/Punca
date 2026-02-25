import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/roadmap_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

import 'package:punca_ai/features/student/analysis/remediation_sheet.dart';
import 'package:punca_ai/core/services/gemini_service.dart';
import 'package:punca_ai/core/widgets/loading_overlay.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/features/student/analysis/widgets/score_card.dart';
import 'package:punca_ai/features/student/analysis/widgets/confidence_card.dart';
import 'package:punca_ai/features/student/analysis/widgets/weakness_card.dart';

class AnalysisResultScreen extends StatelessWidget {
  final AssessmentResult result;

  const AnalysisResultScreen({super.key, required this.result});

  Future<void> _handlePractice(BuildContext context, Weakness weakness) async {
    try {
      // 1. Check if drill already exists
      RemediationDrill? drill;
      try {
        drill = result.remediationDrills.firstWhere(
          (d) => d.weaknessId == weakness.id,
        );
      } catch (_) {
        drill = null;
      }

      if (drill == null) {
        // 2. Generate if missing
        drill = await LoadingOverlay.show<RemediationDrill?>(
          context: context,
          message: "让我教你做人😉...",
          asyncTask: () => GeminiService().generateRemediation(weakness),
        );

        // 3. Save if generated successfully
        if (drill != null) {
          result.remediationDrills.add(drill);
          FirebaseService().updateAssessment(result);
        }
      }

      if (drill != null && context.mounted) {
        // Collect all drills for this weakness (base + challenges)
        final allDrills = result.remediationDrills
            .where((d) => d.weaknessId == weakness.id)
            .toList();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => RemediationSheet(
            drill: drill!,
            weakness: weakness,
            drillHistory: allDrills,
            onMorePractice: () {},
            onDrillUpdated: (updatedDrills) {
              // Replace all drills for this weakness with the updated history
              result.remediationDrills.removeWhere(
                (d) => d.weaknessId == weakness.id,
              );
              result.remediationDrills.addAll(updatedDrills);
              FirebaseService().updateAssessment(result);
            },
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate drill. Try again.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

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
            ScoreCard(subject: result.subject, grade: result.grade),
            const SizedBox(height: 24),
            ConfidenceCard(message: result.confidenceBuilder),
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
                return WeaknessCard(
                  weakness: w,
                  onPractice: () => _handlePractice(context, w),
                );
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

  void _showImages(BuildContext context, List<String> paths) {
    // Check if any path is a PDF
    final bool hasPdf = paths.any((p) => p.toLowerCase().endsWith('.pdf'));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: hasPdf ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Original Work (${paths.length} ${hasPdf ? 'file' : 'pages'})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasPdf
                  ? _buildPdfViewer(paths.first)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: paths.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImageWidget(paths[index]),
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

  Widget _buildPdfViewer(String path) {
    if (path.startsWith('http')) {
      // Network PDF — show a message (would need download first)
      return const Center(
        child: Text('PDF preview not available for cloud files'),
      );
    }
    return PDFView(
      filePath: path,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.contain);
    }
    return Image.file(File(path), fit: BoxFit.contain);
  }
}
