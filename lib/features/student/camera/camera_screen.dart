import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';

import 'package:image_picker/image_picker.dart';

import 'package:punca_ai/core/services/gemini_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/core/widgets/loading_overlay.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  Future<void> _pickImages(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty && context.mounted) {
        final paths = images.map((e) => e.path).toList();
        _showAnalysisProgress(context, imagePaths: paths, images: images);
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Placeholder for Camera Preview
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[900],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 80,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Please select from Gallery",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),

          // Guidelines Overlay
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            bottom: 200,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Select multiple pages if needed",
                    style: TextStyle(
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Exit Button
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    // Take Picture Button (DISABLED/TOAST)
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Camera is currently unavailable. Please use Gallery.",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[400], // Greyed out
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 4),
                        ),
                        child: const Icon(
                          Icons.no_photography,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    // Pick from Gallery Button
                    IconButton(
                      onPressed: () => _pickImages(context),
                      icon: const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 30,
                      ),
                      tooltip: "Pick from Gallery",
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Tap Gallery to Select Pages",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAnalysisProgress(
    BuildContext context, {
    required List<String> imagePaths,
    required List<XFile> images,
  }) async {
    if (imagePaths.isEmpty) return;

    // 1. Show Overlay and wait for data
    final assessment = await LoadingOverlay.show<AssessmentResult?>(
      context: context,
      message:
          "Analyzing ${imagePaths.length} page${imagePaths.length > 1 ? 's' : ''}...\n让我检查这个人类的所作所为，只有我能为所欲为",
      asyncTask: () => _analyzeImages(context, imagePaths, images),
    );

    // 2. Navigate only AFTER overlay is closed
    if (assessment != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: assessment),
        ),
      );
    }
  }

  Future<AssessmentResult?> _analyzeImages(
    BuildContext context,
    List<String> imagePaths,
    List<XFile> images,
  ) async {
    final service = GeminiService();
    // Delay slightly to allow UI to build/transition
    await Future.delayed(const Duration(milliseconds: 500));

    // Notice: We don't check context.mounted here as strict because we want the task to finish
    // and return data even if user backgrounded app, though context is needed for saving?
    // Actually, saving needs context for nothing specific except maybe error showing?
    // Let's keep existing logic but return result.

    try {
      final resultMap = await service.analyzeImages(images);

      if (resultMap != null) {
        if (context.mounted) {
          return await _uploadAndSaveResults(context, imagePaths, resultMap);
        }
      } else {
        if (context.mounted) {
          _showError(context, "Failed to analyze image. Please try again.");
        }
      }
    } catch (e) {
      debugPrint("Analysis error: $e");
      if (context.mounted) {
        _showError(context, "An unexpected error occurred: $e");
      }
      rethrow;
    }
    return null;
  }

  Future<AssessmentResult?> _uploadAndSaveResults(
    BuildContext context,
    List<String> imagePaths,
    Map<String, dynamic> result,
  ) async {
    try {
      final fbService = FirebaseService();
      List<String> uploadedUrls = [];

      final user = AuthService().currentUser;
      final studentId = user?.uid ?? "unknown_student";
      final String paperId = "paper_${DateTime.now().millisecondsSinceEpoch}";
      final String storageFolder = "users/$studentId/papers/$paperId";

      debugPrint("Uploading images to: $storageFolder");

      for (var i = 0; i < imagePaths.length; i++) {
        final path = imagePaths[i];
        final String fileName = "$storageFolder/page_${i + 1}.jpg";

        final String? imageUrl = await fbService.uploadImage(path, fileName);
        if (imageUrl != null) uploadedUrls.add(imageUrl);
      }

      if (uploadedUrls.isNotEmpty) {
        debugPrint("Saving assessment for studentId: $studentId");

        // Create AssessmentResult object
        final assessment = AssessmentResult.fromAnalysis(
          studentId: studentId,
          imageUrls: uploadedUrls,
          json: result,
        );

        final docId = await fbService.saveAssessment(assessment);
        final savedAssessment = assessment.copyWith(id: docId);

        debugPrint("Assessment saved successfully with ID: $docId");
        return savedAssessment; // Return the object with the ID
      }
    } catch (e) {
      debugPrint("Firebase upload/save failed: $e");
      if (context.mounted) {
        _showError(context, "Failed to save results: $e");
      }
      // Don't rethrow here if you want to keep the overlay closed but stay on screen?
      // Actually LoadingOverlay closes on rethrow.
      // If we return null, overlay closes and we stay here.
      // If we want to show error inside this function, we do.
      rethrow;
    }
    return null;
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Analysis Error"),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
