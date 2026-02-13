import 'dart:math';

import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/services/firebase_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, String> student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<Map<String, double>> _gapAnalysisFuture;
  bool _isLoadingRemediation = false;

  @override
  void initState() {
    super.initState();
    final studentId = widget.student['id'];
    if (studentId != null && !studentId.startsWith('mock_')) {
      _gapAnalysisFuture = FirebaseService().getGapAnalysis(studentId);
    } else {
      // Mock Data
      _gapAnalysisFuture = Future.value({
        'foundation': 0.15,
        'execution': 0.60,
        'precision': 0.25,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is the "Real" student
    final isRealStudent = !widget.student['id']!.startsWith('mock_');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student['name']!),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(isRealStudent),
            const SizedBox(height: 24),
            _buildMistakeComposition(isRealStudent),
            const SizedBox(height: 24),
            _buildActionableSteps(context, isRealStudent),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(bool isRealStudent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: isRealStudent ? Colors.red[100] : Colors.blue[100],
            child: Text(
              widget.student['score']!.replaceAll('%', ''),
              style: TextStyle(
                color: isRealStudent ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student['name']!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  widget.student['issue']!,
                  style: TextStyle(
                    color: isRealStudent ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeComposition(bool isRealStudent) {
    return FutureBuilder<Map<String, double>>(
      future: _gapAnalysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data =
            snapshot.data ??
            {'foundation': 0.33, 'execution': 0.33, 'precision': 0.34};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRealStudent
                  ? "Mistake Composition (Real Data)"
                  : "Mistake Composition (Mock)",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Pie Chart Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Simple Custom Pie Chart
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CustomPaint(painter: _SimplePieChartPainter(data)),
                  ),
                  const SizedBox(width: 24),
                  // Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(
                          "Concept",
                          data['foundation']!,
                          Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          "Process",
                          data['execution']!,
                          Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        _buildLegendItem(
                          "Careless",
                          data['precision']!,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Top Weakness Areas
            const Text(
              "Top 3 Weak Topics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWeakTopicItem("1. Algebraic Expansion", "Concept Error"),
            _buildWeakTopicItem("2. Factorisation", "Process Error"),
            _buildWeakTopicItem("3. Linear Equations", "Careless Error"),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String label, double pct, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          "$label ${(pct * 100).toInt()}%",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWeakTopicItem(String topic, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(topic, style: TextStyle(color: Colors.grey[800], fontSize: 15)),
          Text(
            reason,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableSteps(BuildContext context, bool isRealStudent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommended Action",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => _isLoadingRemediation = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (context.mounted) {
                  setState(() => _isLoadingRemediation = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Targeted Remediation Pack Assigned!"),
                    ),
                  );
                }
              });
            },
            icon: _isLoadingRemediation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.assignment_turned_in),
            label: Text(
              _isLoadingRemediation
                  ? "Generating Pack..."
                  : "Assign Targeted Remediation Pack",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimplePieChartPainter extends CustomPainter {
  final Map<String, double> data;

  _SimplePieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    double startAngle = -pi / 2;

    // Colors mapping
    final colors = {
      'foundation': Colors.red,
      'execution': Colors.orange,
      'precision': Colors.blue,
    };

    data.forEach((key, value) {
      final sweepAngle = 2 * pi * value;
      final paint = Paint()
        ..color = colors[key] ?? Colors.grey
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    });

    // Draw hole for Donut effect (optional, looks nicer)
    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
