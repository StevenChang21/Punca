import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/teacher/widgets/gap_analysis_chart.dart';

import 'package:punca_ai/core/services/firebase_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, String> student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<Map<String, double>> _gapAnalysisFuture;

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
    // Check if this is the "Real" student (Alex Johnson / You)
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
            _buildWeaknessAnalysis(isRealStudent),
            const SizedBox(height: 24),
            _buildActionableSteps(context),
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

  Widget _buildWeaknessAnalysis(bool isRealStudent) {
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
                  ? "Your Gap Analysis (Real Data)"
                  : "Weakness Breakdown (Mock)",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Real Gap Analysis Chart
            GapAnalysisChart(
              foundationPct: data['foundation']!,
              executionPct: data['execution']!,
              precisionPct: data['precision']!,
            ),
            const SizedBox(height: 24),
            // Existing Skill Bars (Static for now, could be dynamic later)
            if (isRealStudent) ...[
              const Text(
                "Top Weakness Areas:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
            ],
            _buildSkillBar("Algebraic Expansion", 0.40, Colors.red),
            _buildSkillBar("Factorisation", 0.55, Colors.orange),
          ],
        );
      },
    );
  }

  Widget _buildSkillBar(String skill, double mastery, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                "${(mastery * 100).toInt()}%",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: mastery,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableSteps(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommended Remediation",
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Remediation Pack Assigned!")),
              );
            },
            icon: const Icon(Icons.assignment),
            label: const Text("Assign Remediation Pack"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
