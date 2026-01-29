import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';

import 'dart:io';
import 'dart:convert';
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
        _showProcessingMock(context, imagePaths: paths);
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

  void _showProcessingMock(
    BuildContext context, {
    required List<String> imagePaths,
  }) {
    // Start analysis immediately
    if (imagePaths.isNotEmpty) {
      _analyzeImages(context, imagePaths);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false, // Prevent dismissing while analyzing
      isDismissible: false,
      builder: (context) => Container(
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
      ),
    );
  }

  Future<void> _analyzeImages(
    BuildContext context,
    List<String> imagePaths,
  ) async {
    final service = GeminiService();
    // Delay slightly to allow UI to build
    await Future.delayed(const Duration(seconds: 1));

    // ignore: use_build_context_synchronously
    if (!context.mounted) return;

    final resultStr = await service.analyzeImages(imagePaths);

    // ignore: use_build_context_synchronously
    if (!context.mounted) return;
    Navigator.pop(context); // Close loading sheet

    if (resultStr != null && !resultStr.startsWith("Error")) {
      try {
        // Clean markdown code blocks if present data
        var cleanJson = resultStr
            .replaceAll('```json', '')
            .replaceAll('```', '');
        final Map<String, dynamic> result = jsonDecode(cleanJson);

        // Upload to Firebase
        try {
          final fbService = FirebaseService();
          List<String> uploadedUrls = [];

          for (var path in imagePaths) {
            final String fileName =
                "${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}.jpg";
            final String? imageUrl = await fbService.uploadImage(
              path,
              fileName,
            );
            if (imageUrl != null) uploadedUrls.add(imageUrl);
          }

          if (uploadedUrls.isNotEmpty) {
            final user = AuthService().currentUser;
            final studentId = user?.uid ?? "unknown_student";
            print("Saving assessment for studentId: $studentId");

            await fbService.saveAssessment(
              studentId: studentId,
              imageUrls: uploadedUrls,
              aiAnalysis: result,
            );
            print("Assessment saved successfully!");

            if (result.containsKey('weaknesses') &&
                result['weaknesses'] is List) {
              await fbService.saveWeaknesses(
                studentId: studentId,
                weaknesses: result['weaknesses'],
              );
            }
          }
        } catch (e) {
          debugPrint("Firebase upload failed: $e");
        }

        // ignore: use_build_context_synchronously
        if (!context.mounted) return;

        // Pass simple image path (first one) or modify result screen to take list
        // For now, passing first image as 'imagePath' to preserve simple compatibility,
        // or we can update AnalysisResultScreen next.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AnalysisResultScreen(result: result, imagePaths: imagePaths),
          ),
        );
      } catch (e) {
        debugPrint("Error parsing JSON: $e");
        _showError(
          context,
          "Failed to parse analysis results. \nRow output: $resultStr",
        );
      }
    } else {
      _showError(context, resultStr ?? "Unknown error occurred");
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
