import 'package:flutter/material.dart';
import 'dart:math';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/features/teacher/classroom_detail_screen.dart';

class ClassroomListScreen extends StatelessWidget {
  const ClassroomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Classrooms
    final classrooms = [
      {
        "id": "MATH-F2-A",
        "name": "Form 2 Mathematics",
        "code": "MTH-2024",
        "form": "Form 2",
        "standard": "KSSM",
        "studentCount": 24,
        "average": 72,
        "color": Colors.blue,
      },
      {
        "id": "SCI-F1-B",
        "name": "Form 1 Science",
        "code": "SCI-1011",
        "form": "Form 1",
        "standard": "KSSM",
        "studentCount": 30,
        "average": 65,
        "color": Colors.green,
      },
      {
        "id": "ADD-F4-C",
        "name": "Form 4 Add Math",
        "code": "ADD-4044",
        "form": "Form 4",
        "standard": "KSSM",
        "studentCount": 18,
        "average": 58, // Low avg
        "color": Colors.orange,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "All Classrooms",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Manage your students and view insights",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final classroom = classrooms[index];
                return _buildClassroomCard(context, classroom);
              }, childCount: classrooms.length),
            ),
          ),
          // Floating Action Button Placeholder (in Sliver)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () {
                  _showCreateClassDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text("Create New Class"),
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
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(
    BuildContext context,
    Map<String, dynamic> classroom,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ClassroomDetailScreen(classroom: classroom),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (classroom['color'] as Color).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        classroom['form'],
                        style: TextStyle(
                          color: classroom['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  classroom['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${classroom['standard']} • ${classroom['studentCount']} Students",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMiniStat(
                      Icons.bar_chart,
                      "${classroom['average']}% Avg",
                    ),
                    const SizedBox(width: 16),
                    _buildMiniStat(
                      Icons.warning_amber_rounded,
                      "3 At Risk",
                      isWarning: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, {bool isWarning = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isWarning ? Colors.orange : Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isWarning ? Colors.orange : Colors.grey[700],
          ),
        ),
      ],
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
