import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';

import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/features/student/camera/camera_screen.dart';
import 'package:punca_ai/features/student/analysis/history_screen.dart';
import 'package:punca_ai/features/student/analysis/analysis_result_screen.dart';
import 'package:punca_ai/core/models/assessment_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<List<AssessmentResult>> _assessmentsFuture;
  String _studentName = "Student";
  int _scannedCount = 0;
  int _weakAreaCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUserName();
    _loadStats();
  }

  Future<void> _loadUserName() async {
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      final name = await AuthService().getUserName(uid);
      if (name != null && mounted) {
        setState(() => _studentName = name.split(' ').first);
      }
    }
  }

  Future<void> _loadStats() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final firebaseService = FirebaseService();
    final scanned = await firebaseService.getAssessmentCount(uid);
    final weakAreas = await firebaseService.getWeaknessCount(uid);
    if (mounted) {
      setState(() {
        _scannedCount = scanned;
        _weakAreaCount = weakAreas;
      });
    }
  }

  void _loadData() {
    setState(() {
      final uid = AuthService().currentUser?.uid;
      debugPrint("Dashboard querying for studentId: $uid");
      if (uid != null) {
        _assessmentsFuture = FirebaseService().getAssessments(uid, limit: 3);
      } else {
        _assessmentsFuture = Future.value([]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $_studentName 👋",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Ready to learn something new?",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionCard(context),
            const SizedBox(height: 16),
            // Join Class Button — standalone
            OutlinedButton.icon(
              onPressed: () => _showJoinClassDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.class_),
              label: const Text("Join a Classroom"),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader("Your Progress"),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSectionHeader("Recent Activity"),
            const SizedBox(height: 16),

            // Dynamic List
            FutureBuilder<List<AssessmentResult>>(
              future: _assessmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Error loading history.",
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${snapshot.error}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                            _loadData();
                            _loadStats();
                          },
                          child: const Text("Open History Screen"),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        "No assessments yet. Snap a picture!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final recent = snapshot.data!;

                return Column(
                  children: [
                    ...recent.map((assessment) {
                      return _buildRecentActivityItem(
                        assessment.subject,
                        "Grade: ${assessment.grade}",
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnalysisResultScreen(result: assessment),
                            ),
                          );
                          _loadData();
                          _loadStats();
                        },
                      );
                    }),
                    if (snapshot.data!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                            _loadData();
                            _loadStats();
                          },
                          child: const Text("View All History"),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Stuck on a question?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Snap a photo and get instant AI-powered help and a personalized study plan.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CameraScreen()));
              _loadData();
              _loadStats();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryDark,
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text("Snap Question"),
          ),
        ],
      ),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    final classroomIdController = TextEditingController();
    final classroomCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join Classroom"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: classroomIdController,
              decoration: const InputDecoration(
                labelText: "Classroom ID",
                hintText: "Enter the Classroom ID",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: classroomCodeController,
              decoration: const InputDecoration(
                labelText: "Classroom Code",
                hintText: "Enter the Access Code",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual join logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Joining Class ID: ${classroomIdController.text} with Code: ${classroomCodeController.text}",
                  ),
                ),
              );
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Scanned",
            "$_scannedCount",
            Icons.document_scanner_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Weak Areas",
            "$_weakAreaCount",
            Icons.warning_amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRecentActivityItem(
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description, color: AppColors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}
