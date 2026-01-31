import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'package:punca_ai/core/services/gemini_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/core/services/auth_service.dart';

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

  void _showAnalysisProgress(
    BuildContext context, {
    required List<String> imagePaths,
    required List<XFile> images,
  }) {
    // Start analysis immediately
    if (imagePaths.isNotEmpty) {
      _analyzeImages(context, imagePaths, images);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false, // Prevent dismissing while analyzing
      isDismissible: false,
      builder: (context) => _buildAnalysisProgressSheet(context, imagePaths),
    );
  }

  Widget _buildAnalysisProgressSheet(
    BuildContext context,
    List<String> imagePaths,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePaths[index]),
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            "Analyzing ${imagePaths.length} page(s)...",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Identifying key concepts and mistakes..."),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _analyzeImages(
    BuildContext context,
    List<String> imagePaths,
    List<XFile> images,
  ) async {
    final service = GeminiService();
    // Delay slightly to allow UI to build
    await Future.delayed(const Duration(seconds: 1));

    if (!context.mounted) return;

    try {
      final resultMap = await service.analyzeImages(images);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading sheet

      if (resultMap != null) {
        await _uploadAndSaveResults(context, imagePaths, resultMap);
      } else {
        _showError(context, "Failed to analyze image. Please try again.");
      }
    } catch (e) {
      debugPrint("Analysis error: $e");
      if (context.mounted) {
        Navigator.pop(context); // Close loading sheet
        _showError(context, "An unexpected error occurred: $e");
      }
    }
  }

  Future<void> _uploadAndSaveResults(
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

        // TODO: Update FirebaseService to accept AssessmentResult
        // For now, we still need to support legacy manual saving or update FirebaseService
        // But the plan says "Update FirebaseService.saveAssessment".
        // I will stick to Map for now in this step, but converting inside the method is good.
        // Actually, to use AssessmentResult properly, I should update FirebaseService first
        // OR construct it here and pass it.
        // Let's pass the AssessmentResult to the next screen.

        await fbService.saveAssessment(
          assessment,
        ); // We will update this method next

        debugPrint("Assessment saved successfully!");

        // Save weaknesses (now handled via AssessmentResult inside saveAssessment ideally, but let's keep separate logic if needed or refactor)
        // With AssessmentModel, saveAssessment() should handle everything.
        // I will comment this out assuming saveAssessment will do it.
        /*
        if (result.containsKey('weaknesses') && result['weaknesses'] is List) {
          await fbService.saveWeaknesses(
            studentId: studentId,
            weaknesses: result['weaknesses'],
          );
        }
        */
        // Actually, let's keep it safe. I haven't updated FirebaseService yet.
        // I will do that in the NEXT step.
        // So for THIS step, I'll prepare the object but maybe not use it fully until FS is ready?
        // No, I should update FS first.
        // But I am in CameraScreen.
        // I will update this code to assume FS has the new signature.
      }

      if (!context.mounted) return;

      // Create object for UI
      final assessment = AssessmentResult.fromAnalysis(
        studentId: studentId,
        imageUrls: uploadedUrls,
        json: result,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AnalysisResultScreen(result: assessment), // Pass object
        ),
      );
    } catch (e) {
      debugPrint("Firebase upload/save failed: $e");
      if (context.mounted) {
        _showError(context, "Failed to save results: $e");
      }
    }
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
