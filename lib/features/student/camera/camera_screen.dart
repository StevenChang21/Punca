import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

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

  Future<void> _pickPdf(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null &&
          result.files.single.path != null &&
          context.mounted) {
        final pdfPath = result.files.single.path!;
        final fileName = result.files.single.name;
        _showAnalysisProgress(
          context,
          imagePaths: [pdfPath],
          images: [],
          pdfPath: pdfPath,
          pdfName: fileName,
        );
      }
    } catch (e) {
      debugPrint("Error picking PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[900],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 80,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Upload your work for AI analysis",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select photos or a PDF file",
                    style: TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                ],
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    // Gallery Button (Photos)
                    _buildUploadButton(
                      icon: Icons.photo_library,
                      label: "Photos",
                      onTap: () => _pickImages(context),
                    ),
                    // PDF Button
                    _buildUploadButton(
                      icon: Icons.picture_as_pdf,
                      label: "PDF",
                      color: Colors.red[400]!,
                      onTap: () => _pickPdf(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Choose Photos or PDF to Analyze",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
    String? pdfPath,
    String? pdfName,
  }) async {
    if (imagePaths.isEmpty) return;

    final isPdf = pdfPath != null;
    final label = isPdf
        ? "Analyzing PDF: ${pdfName ?? 'document'}..."
        : "Analyzing ${imagePaths.length} page${imagePaths.length > 1 ? 's' : ''}...";

    final assessment = await LoadingOverlay.show<AssessmentResult?>(
      context: context,
      message: label,
      asyncTask: () =>
          _analyzeFiles(context, imagePaths, images, pdfPath: pdfPath),
    );

    if (assessment != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(result: assessment),
        ),
      );
    }
  }

  Future<AssessmentResult?> _analyzeFiles(
    BuildContext context,
    List<String> filePaths,
    List<XFile> images, {
    String? pdfPath,
  }) async {
    final service = GeminiService();
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final resultMap = await service.analyzeImages(images, pdfPath: pdfPath);

      if (resultMap != null) {
        if (context.mounted) {
          return await _uploadAndSaveResults(
            context,
            filePaths,
            resultMap,
            isPdf: pdfPath != null,
          );
        }
      } else {
        if (context.mounted) {
          _showError(context, "Failed to analyze. Please try again.");
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
    List<String> filePaths,
    Map<String, dynamic> result, {
    bool isPdf = false,
  }) async {
    try {
      final fbService = FirebaseService();
      List<String> uploadedUrls = [];

      final user = AuthService().currentUser;
      final studentId = user?.uid ?? "unknown_student";
      final String paperId = "paper_${DateTime.now().millisecondsSinceEpoch}";
      final String storageFolder = "users/$studentId/papers/$paperId";

      debugPrint("Uploading files to: $storageFolder");

      if (isPdf) {
        // Upload PDF as-is
        final String fileName = "$storageFolder/document.pdf";
        final String? fileUrl = await fbService.uploadImage(
          filePaths[0],
          fileName,
        );
        if (fileUrl != null) uploadedUrls.add(fileUrl);
      } else {
        for (var i = 0; i < filePaths.length; i++) {
          final path = filePaths[i];
          final String fileName = "$storageFolder/page_${i + 1}.jpg";
          final String? imageUrl = await fbService.uploadImage(path, fileName);
          if (imageUrl != null) uploadedUrls.add(imageUrl);
        }
      }

      if (uploadedUrls.isNotEmpty) {
        debugPrint("Saving assessment for studentId: $studentId");

        final assessment = AssessmentResult.fromAnalysis(
          studentId: studentId,
          imageUrls: uploadedUrls,
          json: result,
        );

        final docId = await fbService.saveAssessment(assessment);
        final savedAssessment = assessment.copyWith(id: docId);

        debugPrint("Assessment saved successfully with ID: $docId");
        return savedAssessment;
      }
    } catch (e) {
      debugPrint("Firebase upload/save failed: $e");
      if (context.mounted) {
        _showError(context, "Failed to save results: $e");
      }
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
