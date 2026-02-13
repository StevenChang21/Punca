import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/core/services/firebase_service.dart';

/// Detail page for a student's enrolled classroom.
/// Shows class info, classmates, homework placeholder, and a subtle Leave button.
class StudentClassroomDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classroom;

  const StudentClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<StudentClassroomDetailScreen> createState() =>
      _StudentClassroomDetailScreenState();
}

class _StudentClassroomDetailScreenState
    extends State<StudentClassroomDetailScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final classroomId = widget.classroom['id'] as String;
    final members = await FirebaseService().getClassroomMembers(classroomId);
    if (mounted) {
      setState(() {
        _members = members;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final className = widget.classroom['name'] ?? 'Classroom';
    final teacherName = widget.classroom['teacherName'] ?? 'Teacher';
    final code = widget.classroom['code'] ?? '';
    final studentCount = widget.classroom['studentCount'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(className),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
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
                  Text(
                    className,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        teacherName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(Icons.people, "$studentCount students"),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.vpn_key, code),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Classmates Section
            const Text(
              "Classmates",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _members.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        "No classmates yet. Share the code!",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _members.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final isMe =
                            member['uid'] == AuthService().currentUser?.uid;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              (member['displayName'] as String)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            "${member['displayName']}${isMe ? ' (You)' : ''}",
                            style: TextStyle(
                              fontWeight: isMe
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle:
                              member['form'] != null &&
                                  (member['form'] as String).isNotEmpty
                              ? Text(member['form'])
                              : null,
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 28),

            // Homework Section (placeholder)
            const Text(
              "Homework",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 40,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No homework assigned yet",
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Leave Class — subtle
            Center(
              child: TextButton(
                onPressed: () => _confirmLeave(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                child: const Text(
                  "Leave this classroom",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    final classroomId = widget.classroom['id'] as String;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Classroom?"),
        content: const Text(
          "Are you sure you want to leave? You can rejoin later with the code.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final uid = AuthService().currentUser?.uid;
              if (uid == null) return;
              Navigator.pop(ctx);
              await FirebaseService().leaveClassroom(uid, classroomId);
              if (mounted) {
                Navigator.pop(context, true); // Return true = left class
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Leave"),
          ),
        ],
      ),
    );
  }
}
