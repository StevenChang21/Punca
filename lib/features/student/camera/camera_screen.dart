import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

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
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
                          border: Border.all(color: AppColors.primary, width: 4),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.image, color: Colors.white, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Tap to Snap", style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showProcessingMock(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              "Analyzing your work...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Identifying key concepts and mistakes..."),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalysisResultScreen()),
                );
              },
              child: const Text("View Results (Mock)"),
            )
          ],
        ),
      ),
    );
  }
}
