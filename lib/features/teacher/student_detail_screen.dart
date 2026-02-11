import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

class StudentDetailScreen extends StatelessWidget {
  final Map<String, String> student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    // Mock Data for "Alex Johnson" failing Linear Equations
    // In a real app, this would be fetched based on student ID
    final isDemoStudent = student['name'] == "Alex Johnson";

    return Scaffold(
      appBar: AppBar(
        title: Text(student['name']!),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(isDemoStudent),
            const SizedBox(height: 24),
            _buildWeaknessAnalysis(isDemoStudent),
            const SizedBox(height: 24),
            _buildActionableSteps(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(bool isDemoStudent) {
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
            backgroundColor: isDemoStudent ? Colors.red[100] : Colors.blue[100],
            child: Text(
              isDemoStudent ? "42%" : "B",
              style: TextStyle(
                color: isDemoStudent ? Colors.red : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student['name']!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                student['issue']!,
                style: TextStyle(
                  color: isDemoStudent ? Colors.red : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeaknessAnalysis(bool isDemoStudent) {
    if (!isDemoStudent) {
      return const Center(
        child: Text("Detailed analysis not available for mock student."),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Weakness Breakdown: Linear Equations I",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSkillBar("Balancing Equations", 0.20, Colors.red),
        _buildSkillBar("Isolating Variables", 0.45, Colors.orange),
        _buildSkillBar("Basic Arithmetic", 0.85, Colors.green),
      ],
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
            label: const Text("Assign 'Linear Equations I' Basics Pack"),
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
