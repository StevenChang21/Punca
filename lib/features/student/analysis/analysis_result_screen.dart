import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/roadmap_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
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
          // Fire and forget save (or await if critical, but for UX speed let's just trigger it)
          FirebaseService().updateAssessment(result);
        }
      }

      if (drill != null && context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => RemediationSheet(
            drill: drill!,
            weakness: weakness,
            onMorePractice: () {}, // Optional future expansion
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
}
