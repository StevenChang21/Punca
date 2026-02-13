import 'package:flutter/material.dart';
import 'dart:math';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _buildGlobalStats(),
          const SizedBox(height: 24),
          _buildAlertsSection(),
          const SizedBox(height: 24),
          _buildQuickActions(context),
        ],
      ),
    );
  }

  Widget _buildGlobalStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Total Students",
            "72",
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Avg Mastery",
            "68%",
            Icons.bar_chart,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Needs Attention",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildAlertCard(
          "5 Students Failing Linear Equations",
          "Form 2 Mathematics",
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildAlertCard(
          "Homework Submission Overdue",
          "Form 4 Add Math",
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildAlertCard(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                "Create Class",
                Icons.add_box_outlined,
                Colors.indigo,
                () {
                  _showCreateClassDialog(context);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                "Broadcast",
                Icons.send_outlined,
                Colors.purple,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Broadcast functionality coming soon!"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final classNameController = TextEditingController();
    final generatedCode = _generateCode();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create New Classroom"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: classNameController,
              decoration: const InputDecoration(
                labelText: "Class Name",
                hintText: "e.g. Form 2 Mathematics",
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Generated Code",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    generatedCode,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = classNameController.text.trim();
              if (name.isEmpty) return;

              final user = AuthService().currentUser;
              if (user == null) return;

              final userName = await AuthService().getUserName(user.uid);

              final classroomId = await FirebaseService().createClassroom(
                teacherId: user.uid,
                teacherName: userName ?? user.email ?? 'Teacher',
                className: name,
                code: generatedCode,
              );

              if (!context.mounted) return;
              Navigator.pop(ctx);

              // Show success with ID and Code
              showDialog(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text("Classroom Created! 🎉"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Share these with your students:"),
                      const SizedBox(height: 16),
                      _buildInfoRow("Classroom ID", classroomId),
                      const SizedBox(height: 8),
                      _buildInfoRow("Access Code", generatedCode),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: const Text("Done"),
                    ),
                  ],
                ),
              );
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
