import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:punca_ai/core/models/assessment_model.dart';

class Assignment {
  final String id;
  final String studentId;
  final String teacherId;
  final String? classroomId;
  final DateTime assignedDate;
  final String topic;
  final String weaknessId;
  final RemediationDrill remediationDrill;
  final String status; // 'pending' or 'completed'
  final int? score;

  Assignment({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.classroomId,
    required this.assignedDate,
    required this.topic,
    required this.weaknessId,
    required this.remediationDrill,
    this.status = 'pending',
    this.score,
  });

  factory Assignment.fromMap(Map<String, dynamic> data, String id) {
    return Assignment(
      id: id,
      studentId: data['studentId'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      classroomId: data['classroomId'] as String?,
      assignedDate:
          (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      topic: data['topic'] as String? ?? 'General Practice',
      weaknessId: data['weaknessId'] as String? ?? '',
      remediationDrill: RemediationDrill.fromJson(
        data['remediationDrill'] as Map<String, dynamic>? ?? {},
      ),
      status: data['status'] as String? ?? 'pending',
      score: data['score'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'teacherId': teacherId,
      'classroomId': classroomId,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'topic': topic,
      'weaknessId': weaknessId,
      'remediationDrill': remediationDrill.toMap(),
      'status': status,
      'score': score,
    };
  }
}
