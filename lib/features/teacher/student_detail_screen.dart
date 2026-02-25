import 'dart:math';

import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/features/student/analysis/widgets/math_display.dart';
import 'package:punca_ai/shared/widgets/work_viewer_dialog.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, String> student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Future<Map<String, double>> _gapAnalysisFuture;
  List<_WeakTopicInfo> _weakTopics = [];
  bool _isLoadingRemediation = false;
  bool _loadingTopics = true;
  final Set<int> _expandedTopics = {};

  @override
  void initState() {
    super.initState();
    final studentId = widget.student['id'];
    if (studentId != null && !studentId.startsWith('mock_')) {
      _gapAnalysisFuture = FirebaseService().getGapAnalysis(studentId);
      _loadWeakTopics(studentId);
    } else {
      _gapAnalysisFuture = Future.value({
        'foundation': 0.15,
        'execution': 0.60,
        'precision': 0.25,
      });
      _weakTopics = [
        _WeakTopicInfo(
          topic: 'Algebraic Expansion',
          errorType: 'Concept Error',
          syllabusRef: 'F2 Ch3',
          reason: 'Did not understand the concept of expanding brackets',
          action: 'Review Ch 3.2. Practice expanding brackets step by step.',
        ),
        _WeakTopicInfo(
          topic: 'Factorisation',
          errorType: 'Process Error',
          syllabusRef: 'F2 Ch4',
          reason: 'Correct method but made sign errors during factoring',
          action: 'Review Ch 4.1. Careful with negative signs.',
        ),
        _WeakTopicInfo(
          topic: 'Linear Equations',
          errorType: 'Careless Error',
          syllabusRef: 'F1 Ch6',
          reason: 'Correct approach but arithmetic slip in final step',
          action: 'Review Ch 6.1. Double-check final calculations.',
        ),
      ];
      _loadingTopics = false;
    }
  }

  Future<void> _loadWeakTopics(String studentId) async {
    try {
      final assessments = await FirebaseService().getAssessments(
        studentId,
        limit: 20,
      );

      // Collect all weaknesses and count occurrences
      final topicMap = <String, _WeakTopicInfo>{};

      for (final a in assessments) {
        for (final w in a.weaknesses) {
          final key = w.topic;
          if (key.isEmpty) continue;

          if (!topicMap.containsKey(key)) {
            // Resolve syllabus reference with chapter + subtopic
            String syllabusLabel = '';
            if (w.syllabusRefs.isNotEmpty) {
              final ref = w.syllabusRefs.first;
              final chapterTitle = _getChapterTitle(ref.form, ref.chapterId);
              final subtopicName = _getSubtopicName(
                ref.form,
                ref.chapterId,
                ref.subtopicId,
              );

              if (chapterTitle != null) {
                syllabusLabel =
                    'F${ref.form} Ch${ref.chapterId}: $chapterTitle';
                if (subtopicName != null) {
                  syllabusLabel += ' › $subtopicName';
                }
              } else {
                syllabusLabel = 'F${ref.form} Ch${ref.chapterId}';
              }
            }

            final gapLabel = switch (w.gapType) {
              GapType.foundation => 'Concept Error',
              GapType.execution => 'Process Error',
              GapType.precision => 'Careless Error',
              GapType.general => 'General',
            };

            topicMap[key] = _WeakTopicInfo(
              topic: key,
              errorType: gapLabel,
              syllabusRef: syllabusLabel,
              reason: w.reason,
              action: w.action,
              imageUrls: List<String>.from(a.imageUrls),
            );
          }
          topicMap[key]!.count++;
        }
      }

      // Sort by frequency, take top 3
      final sorted = topicMap.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      if (mounted) {
        setState(() {
          _weakTopics = sorted.take(3).toList();
          _loadingTopics = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading weak topics: $e");
      if (mounted) setState(() => _loadingTopics = false);
    }
  }

  String? _getChapterTitle(int form, int chapterId) {
    final chapters = KssmSyllabus.structure[form];
    if (chapters == null) return null;
    for (final ch in chapters) {
      if (ch.id == chapterId) return ch.title;
    }
    return null;
  }

  String? _getSubtopicName(int form, int chapterId, int? subtopicId) {
    if (subtopicId == null) return null;
    final chapters = KssmSyllabus.structure[form];
    if (chapters == null) return null;
    for (final ch in chapters) {
      if (ch.id == chapterId) return ch.subtopics[subtopicId];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: CustomPaint(painter: _SimplePieChartPainter(data)),
                  ),
                  const SizedBox(width: 24),
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
            // Weak Topics
            const Text(
              "Top Weak Topics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWeakTopicsList(),
          ],
        );
      },
    );
  }

  Widget _buildWeakTopicsList() {
    if (_loadingTopics) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_weakTopics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "No weakness data available",
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return Column(
      children: _weakTopics.asMap().entries.map((entry) {
        final idx = entry.key + 1;
        final info = entry.value;
        return _buildWeakTopicCard(idx, info);
      }).toList(),
    );
  }

  Widget _buildWeakTopicCard(int rank, _WeakTopicInfo info) {
    final errorColor = switch (info.errorType) {
      'Concept Error' => Colors.red,
      'Process Error' => Colors.orange,
      'Careless Error' => Colors.blue,
      _ => Colors.grey,
    };

    final isExpanded = _expandedTopics.contains(rank);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedTopics.remove(rank);
          } else {
            _expandedTopics.add(rank);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded ? errorColor.withValues(alpha: 0.03) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? errorColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "$rank",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: errorColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.topic,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (info.syllabusRef.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          info.syllabusRef,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    info.errorType,
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            // Expandable reason + action
            if (isExpanded &&
                (info.reason.isNotEmpty || info.action.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: errorColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (info.reason.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: errorColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: MixedMathText(
                              content: info.reason,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (info.reason.isNotEmpty && info.action.isNotEmpty)
                      const Divider(height: 16),
                    if (info.action.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: MixedMathText(
                              content: info.action,
                              textStyle: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // View Work button
            if (isExpanded && info.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: TextButton.icon(
                    onPressed: () =>
                        showWorkViewerDialog(context, info.imageUrls),
                    icon: const Icon(Icons.image_outlined, size: 16),
                    label: const Text('View Student Work'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (!isExpanded &&
                (info.reason.isNotEmpty || info.action.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 40),
                child: Text(
                  "Tap to see reasoning ›",
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ),
          ],
        ),
      ),
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

// ── Data Class ──
class _WeakTopicInfo {
  final String topic;
  final String errorType;
  final String syllabusRef;
  final String reason;
  final String action;
  final List<String> imageUrls;
  int count;

  _WeakTopicInfo({
    required this.topic,
    required this.errorType,
    required this.syllabusRef,
    this.reason = '',
    this.action = '',
    this.imageUrls = const [],
  }) : count = 0;
}

// ── Pie Chart Painter ──
class _SimplePieChartPainter extends CustomPainter {
  final Map<String, double> data;

  _SimplePieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    double startAngle = -pi / 2;

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

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, holePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
