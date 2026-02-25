import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/features/teacher/student_detail_screen.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final Map<String, dynamic> classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  // Aggregated stats
  double? _classAverage;
  String _topWeakness = 'N/A';
  int _topWeaknessCount = 0;
  Map<String, double> _topicAverages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final classroomId = widget.classroom['id'] as String;
    final members = await FirebaseService().getClassroomMembers(classroomId);

    // Aggregate stats across all students
    double totalScore = 0;
    int scoreCount = 0;
    final weaknessCounts = <String, int>{};
    final topicScores = <String, List<double>>{};

    for (final member in members) {
      final uid = member['uid'] as String;

      // Get assessments for each student
      final assessments = await FirebaseService().getAssessments(
        uid,
        limit: 50,
      );
      for (final a in assessments) {
        // Parse grade to numeric
        final grade = _gradeToPercent(a.grade);
        if (grade != null) {
          totalScore += grade;
          scoreCount++;
        }

        // Count weaknesses
        for (final w in a.weaknesses) {
          final topic = w.topic;
          if (topic.isNotEmpty) {
            weaknessCounts[topic] = (weaknessCounts[topic] ?? 0) + 1;
          }
        }

        // Aggregate by subject/topic for heatmap
        final subject = a.subject;
        if (grade != null && subject.isNotEmpty) {
          topicScores.putIfAbsent(subject, () => []).add(grade);
        }
      }
    }

    // Calculate averages
    final avg = scoreCount > 0 ? totalScore / scoreCount : null;

    // Find top weakness
    String topWeak = 'N/A';
    int topWeakCount = 0;
    if (weaknessCounts.isNotEmpty) {
      final sorted = weaknessCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topWeak = sorted.first.key;
      topWeakCount = sorted.first.value;
    }

    // Topic averages for heatmap
    final topicAvg = <String, double>{};
    for (final entry in topicScores.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      topicAvg[entry.key] = sum / entry.value.length / 100;
    }

    if (mounted) {
      setState(() {
        _members = members;
        _loading = false;
        _classAverage = avg;
        _topWeakness = topWeak;
        _topWeaknessCount = topWeakCount;
        _topicAverages = topicAvg;
      });
    }
  }

  double? _gradeToPercent(String grade) {
    // Try parsing as number first (e.g. "72" or "72%")
    final cleaned = grade.replaceAll('%', '').trim();
    final parsed = double.tryParse(cleaned);
    if (parsed != null) return parsed;

    // Letter grade mapping
    final letterGrades = {
      'A+': 95,
      'A': 90,
      'A-': 87,
      'B+': 83,
      'B': 80,
      'B-': 77,
      'C+': 73,
      'C': 70,
      'C-': 67,
      'D+': 63,
      'D': 60,
      'D-': 57,
      'F': 40,
    };
    return letterGrades[grade.trim().toUpperCase()]?.toDouble();
  }

  String _percentToGrade(double percent) {
    if (percent >= 90) return 'A';
    if (percent >= 80) return 'B';
    if (percent >= 70) return 'C';
    if (percent >= 60) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classroom['name'] ?? 'Classroom'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: "View Class Code",
            onPressed: () => _showClassCode(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: "Delete Classroom",
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClassInfo(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildHeatmap(),
                    const SizedBox(height: 24),
                    _buildSectionHeader("Enrolled Students"),
                    const SizedBox(height: 16),
                    _buildStudentList(context),
                  ],
                ),
              ),
            ),
    );
  }

  void _showClassCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Join this Class"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share these with your students:"),
            const SizedBox(height: 16),
            _buildInfoRow("Classroom ID", widget.classroom['id'] ?? ''),
            const SizedBox(height: 12),
            _buildInfoRow("Access Code", widget.classroom['code'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
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

  void _confirmDelete(BuildContext context) {
    final name = widget.classroom['name'] ?? 'this classroom';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Classroom"),
        content: Text(
          "Are you sure you want to delete \"$name\"? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final classroomId = widget.classroom['id'] as String;
              await FirebaseService().deleteClassroom(classroomId);
              if (context.mounted) {
                Navigator.pop(context); // Go back to list
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("\"$name\" deleted")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildClassInfo() {
    final teacherName = widget.classroom['teacherName'] ?? 'Teacher';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Teacher: $teacherName",
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          "${_members.length} Students Enrolled",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final avgDisplay = _classAverage != null
        ? "${_classAverage!.toStringAsFixed(0)}%"
        : "N/A";
    final gradeDisplay = _classAverage != null
        ? "${_percentToGrade(_classAverage!)} Grade"
        : "No data";
    final weakDisplay = _topWeakness.length > 12
        ? "${_topWeakness.substring(0, 12)}..."
        : _topWeakness;
    final weakSubtitle = _topWeaknessCount > 0
        ? "$_topWeaknessCount Students"
        : "No data";

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Class Average",
            avgDisplay,
            Icons.bar_chart,
            _classAverage != null ? Colors.blue : Colors.grey,
            gradeDisplay,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Top Weakness",
            weakDisplay,
            Icons.warning_amber_rounded,
            _topWeaknessCount > 0 ? Colors.orange : Colors.grey,
            weakSubtitle,
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
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Heatmap (live or empty) ──
  Widget _buildHeatmap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Class Heatmap",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_topicAverages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.grid_view, size: 40, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(
                  "No assessment data yet",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Topic heatmap will appear once students submit work",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _topicAverages.length,
            itemBuilder: (context, index) {
              final key = _topicAverages.keys.elementAt(index);
              final score = _topicAverages[key]!;
              return _buildHeatmapTile(key, score);
            },
          ),
      ],
    );
  }

  Widget _buildHeatmapTile(String title, double score) {
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
                Text(
                  "Avg: ${(score * 100).toInt()}%",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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

  // ── Live Student List ──
  Widget _buildStudentList(BuildContext context) {
    if (_members.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "No students enrolled yet",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _members.map((student) {
        final name = student['displayName'] ?? 'Student';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final form = student['form'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailScreen(
                    student: {
                      'name': name,
                      'id': student['uid'].toString(),
                      'issue': form.isNotEmpty ? form : 'Student',
                      'score': 'N/A',
                      'classroomId': widget.classroom['id']?.toString() ?? '',
                    },
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(form.isNotEmpty ? form : 'Student'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }
}
