import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';

import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'package:punca_ai/core/services/gemini_service.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && context.mounted) {
        _showProcessingMock(context, imagePath: image.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
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
                  Icon(Icons.camera_enhance, size: 80, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    "Camera Preview",
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
                    "Align exam paper within frame",
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
                    GestureDetector(
                      onTap: () {
                        // TODO: Take Picture
                        _showProcessingMock(context);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _pickImage(context),
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
                  "Tap to Snap",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProcessingMock(BuildContext context, {String? imagePath}) {
    // Start analysis immediately if image is provided
    if (imagePath != null) {
      _analyzeImage(context, imagePath);
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
            if (imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Icon(Icons.description, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
            ],
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              "Analyzing your work using Gemini...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Identifying key concepts and mistakes..."),
            const SizedBox(height: 32),

            // Hidden button, we auto-navigate now
            /*
            ElevatedButton(
              onPressed: () {},
              child: const Text("Processing..."),
            )
            */
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeImage(BuildContext context, String imagePath) async {
    final service = GeminiService();
    // Delay slightly to allow UI to build
    await Future.delayed(const Duration(seconds: 1));

    // ignore: use_build_context_synchronously
    if (!context.mounted) return;

    final resultStr = await service.analyzeImage(imagePath);

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

        // ignore: use_build_context_synchronously
        if (!context.mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AnalysisResultScreen(result: result, imagePath: imagePath),
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
