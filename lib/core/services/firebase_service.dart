import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'package:punca_ai/core/models/syllabus_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/* id: 3 */
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance; // Unused

  // Collection References
  // CollectionReference get _users => _firestore.collection('users'); // Unused
  CollectionReference get _assessments => _firestore.collection('assessments');
  CollectionReference get _weaknesses => _firestore.collection('weaknesses');

  /// Uploads a file to Firebase Storage and returns the download URL
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(File(filePath));
      final url = await ref.getDownloadURL();
      debugPrint("Uploaded to Firebase Storage: $fileName");
      return url;
    } catch (e) {
      debugPrint("Firebase Storage upload failed: $e");
      // Fallback to local path so the app still works without Storage
      return filePath;
    }
  }

  /// Saves the assessment result to Firestore and returns the document ID
  Future<String> saveAssessment(AssessmentResult result) async {
    try {
      final docRef = await _assessments.add(
        result.toMap(),
      ); // Use cleaner toMap() method
      debugPrint("Assessment saved with ID: ${docRef.id}");

      // Save weaknesses in batch (handled automatically if we want, or keeping separate logic inside if needed)
      // Since toMap() includes 'weaknesses' as a nested list map, Firestore stores it as an array of objects.
      // But if we want the top-level 'weaknesses' collection for querying:
      if (result.weaknesses.isNotEmpty) {
        await saveWeaknesses(
          studentId: result.studentId,
          weaknesses: result.weaknesses.map((w) => w.toMap()).toList(),
        );
      }
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving assessment: $e');
      rethrow;
    }
  }

  /// Updates an existing assessment (e.g. adding remediation drills)
  Future<void> updateAssessment(AssessmentResult result) async {
    if (result.id.isEmpty) {
      debugPrint("Cannot update assessment without ID");
      return;
    }
    try {
      await _assessments.doc(result.id).update(result.toMap());
      debugPrint("Assessment updated: ${result.id}");
    } catch (e) {
      debugPrint("Error updating assessment: $e");
      rethrow;
    }
  }

  /// Saves identified weaknesses to the 'weaknesses' collection
  Future<void> saveWeaknesses({
    required String studentId,
    required List<dynamic> weaknesses,
  }) async {
    final batch = _firestore.batch();

    for (var weakness in weaknesses) {
      final docRef = _weaknesses.doc(); // Auto-ID

      // Extract syllabus reference if available to use as Stable ID
      Map<String, dynamic> syllabusData = {};
      if (weakness['syllabus_refs'] != null &&
          (weakness['syllabus_refs'] as List).isNotEmpty) {
        final ref =
            (weakness['syllabus_refs'] as List).first as Map<String, dynamic>;
        syllabusData = {
          'form_id': ref['form'],
          'chapter_id': ref['chapter_id'],
          'subtopic_id': ref['subtopic_id'],
        };
      }

      batch.set(docRef, {
        'studentId': studentId,
        'topic': weakness['topic'] ?? 'Unknown', // Keep for display
        ...syllabusData, // MERGE IDs: form_id, chapter_id, subtopic_id
        'reason': weakness['reason'] ?? '',
        'gap_type': weakness['gap_type'] ?? 'general',
        'confidenceScore': 50,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      debugPrint('Weaknesses batch committed successfully');
    } catch (e) {
      debugPrint('Error saving weaknesses: $e');
      rethrow;
    }
  }

  /// Get all past assessments for a student (Future based for easy loading)
  Future<List<AssessmentResult>> getAssessments(
    String studentId, {
    int? limit,
  }) async {
    var query = _assessments
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Inject ID from document
      data['id'] = doc.id;
      // Handle timestamp conversion
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }

      // Parse syllabusIds manually here if needed for legacy docs?
      // But fromAnalysis handles it.
      // Need to ensure syllabusMatches is populated if stored differently.
      // AssessmentResult.toMap stores it as 'syllabusIds'.
      // fromAnalysis expects 'syllabus_matches' (Gemini format).
      // We need to bridge this if we want to load from Firestore 'syllabusIds' back into model.
      // Modifying fromAnalysis to check both or create a fromMap factory?
      // Let's rely on fromAnalysis but handle the key mapping:
      if (data['syllabusIds'] != null) {
        data['syllabus_matches'] = data['syllabusIds'];
      }

      return AssessmentResult.fromAnalysis(
        studentId: studentId,
        imageUrls: List<String>.from(data['imageUrls'] ?? []),
        json: data,
      ).copyWith(id: doc.id); // Ensure ID is set
    }).toList();
  }

  /// Deletes all assessments AND weaknesses for a specific student
  Future<void> deleteAllAssessments(String studentId) async {
    try {
      // 1. Delete Assessments
      final assessmentSnapshot = await _assessments
          .where('studentId', isEqualTo: studentId)
          .get();

      for (var doc in assessmentSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Delete Weaknesses
      final weaknessSnapshot = await _weaknesses
          .where('studentId', isEqualTo: studentId)
          .get();

      for (var doc in weaknessSnapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint(
        "Deleted ${assessmentSnapshot.docs.length} assessments and ${weaknessSnapshot.docs.length} weaknesses for $studentId",
      );
    } catch (e) {
      debugPrint("Error deleting all data: $e");
      rethrow;
    }
  }

  /// Calculates mastery stats (average grade) per subject/topic
  /// If [subject] is provided, returns granular breakdown by TOPIC within that subject.
  /// KEY CHANGE: Returns nullable double? (null == unattempted/NA)
  Future<Map<String, double?>> getMasteryStats(
    String studentId, {
    String? subject,
  }) async {
    try {
      final assessments = await getAssessments(studentId);

      // Key -> List of Scores
      Map<String, List<double>> keyScores = {};

      // 1. Pre-fill Syllabus for "Math" keys
      //    But initialize as EMPTY list (indicating unattempted)
      if (subject == "Math") {
        KssmSyllabus.structure.forEach((form, chapters) {
          if (form <= 2) {
            // Demo Restriction
            for (var chap in chapters) {
              final key =
                  "F$form C${chap.id.toString().padLeft(2, '0')}: ${chap.title}";
              keyScores[key] = [];
            }
          }
        });
      }

      if (assessments.isEmpty && subject != "Math") return {};

      // Filter by subject if requested
      final filteredAssessments = subject != null
          ? assessments.where((a) => a.subject == subject).toList()
          : assessments;

      if (filteredAssessments.isEmpty && keyScores.isEmpty) return {};

      // Helper to match Key by ID
      String? findKeyById(int form, int chapter) {
        // Reconstruct the exact string key we used above
        // This is deterministic.
        // We need to look up the title from KssmSyllabus to match exact string
        final chapters = KssmSyllabus.structure[form];
        if (chapters != null) {
          final chap = chapters.firstWhere(
            (c) => c.id == chapter,
            orElse: () =>
                const SyllabusChapter(id: -1, title: 'Unknown', subtopics: {}),
          );
          if (chap.id != -1) {
            return "F$form C${chap.id.toString().padLeft(2, '0')}: ${chap.title}";
          }
        }
        return null;
      }

      for (var assessment in filteredAssessments) {
        double? score = _parseGrade(assessment.grade);
        if (score != null) {
          if (subject == null) {
            // Aggregate by SUBJECT
            if (!keyScores.containsKey(assessment.subject)) {
              keyScores[assessment.subject] = [];
            }
            keyScores[assessment.subject]!.add(score);
          } else if (subject == "Math") {
            // Aggregate by SYLLABUS ID (Robust)
            if (assessment.syllabusIds.isNotEmpty) {
              for (var ptr in assessment.syllabusIds) {
                final key = findKeyById(ptr.form, ptr.chapterId);
                if (key != null) {
                  if (!keyScores.containsKey(key)) {
                    keyScores[key] = [];
                  }
                  keyScores[key]!.add(score);
                }
              }
            } else {
              // Fallback to Topic String matching? Or just ignore?
              // Let's implement fuzzy fallback for old data if needed
              // but prioritize robustness.
            }
          } else {
            // Other subjects generic topic agg
            for (var topic in assessment.topics) {
              if (!keyScores.containsKey(topic)) {
                keyScores[topic] = [];
              }
              keyScores[topic]!.add(score);
            }
          }
        }
      }

      // Calculate Latest Score (Current Mastery)
      Map<String, double?> mastery = {};
      keyScores.forEach((key, scores) {
        if (scores.isEmpty) {
          mastery[key] = null; // Mark as NA
        } else {
          // Since assessments are already fetched with orderBy('createdAt', descending: true)
          // The first score in the list is the LATEST one.
          // No need to average.
          mastery[key] = scores.first / 100.0;
        }
      });

      // Sort and Return
      final sortedKeys = mastery.keys.toList()..sort();
      final Map<String, double?> sortedMastery = {
        for (var k in sortedKeys) k: mastery[k],
      };

      return sortedMastery;
    } catch (e) {
      debugPrint("Error calculating mastery: $e");
      return {};
    }
  }

  double? _parseGrade(String gradeString) {
    // Tries to find a number in "B (76%)" -> 76.0
    final regex = RegExp(r'(\d+)%?');
    final match = regex.firstMatch(gradeString);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Aggregates gap analysis for a specific student (Real Data for Teacher Insights)
  Future<Map<String, double>> getGapAnalysis(String studentId) async {
    try {
      final snapshot = await _weaknesses
          .where('studentId', isEqualTo: studentId)
          .get();

      if (snapshot.docs.isEmpty) {
        // Return default distribution if no data
        return {'foundation': 0.33, 'execution': 0.33, 'precision': 0.34};
      }

      int foundation = 0;
      int execution = 0;
      int precision = 0;
      int total = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final gapType = data['gap_type']?.toString().toLowerCase() ?? 'general';

        if (gapType == 'foundation') {
          foundation++;
        } else if (gapType == 'execution')
          execution++;
        else if (gapType == 'precision')
          precision++;
        else
          execution++; // Default general to execution for now

        total++;
      }

      if (total == 0) {
        return {'foundation': 0.33, 'execution': 0.33, 'precision': 0.34};
      }

      return {
        'foundation': foundation / total,
        'execution': execution / total,
        'precision': precision / total,
      };
    } catch (e) {
      debugPrint("Error getting gap analysis: $e");
      return {'foundation': 0.33, 'execution': 0.33, 'precision': 0.34};
    }
  }

  /// Returns total assessment count for a student
  Future<int> getAssessmentCount(String studentId) async {
    try {
      final snapshot = await _assessments
          .where('studentId', isEqualTo: studentId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint("Error getting assessment count: $e");
      return 0;
    }
  }

  /// Returns count of unique weak topics for a student
  Future<int> getWeaknessCount(String studentId) async {
    try {
      final snapshot = await _weaknesses
          .where('studentId', isEqualTo: studentId)
          .get();
      // Count unique topics
      final uniqueTopics = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final topic = data['topic']?.toString() ?? '';
        if (topic.isNotEmpty) uniqueTopics.add(topic);
      }
      return uniqueTopics.length;
    } catch (e) {
      debugPrint("Error getting weakness count: $e");
      return 0;
    }
  }

  // ── Classroom Methods ──

  /// Create a new classroom. Returns the classroom ID.
  Future<String> createClassroom({
    required String teacherId,
    required String teacherName,
    required String className,
    required String code,
  }) async {
    final docRef = await _firestore.collection('classrooms').add({
      'name': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'code': code,
      'studentIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Delete a classroom (used for test cleanup).
  Future<void> deleteClassroom(String classroomId) async {
    await _firestore.collection('classrooms').doc(classroomId).delete();
  }

  /// Get all classrooms for a teacher.
  Future<List<Map<String, dynamic>>> getTeacherClassrooms(
    String teacherId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('classrooms')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['studentCount'] = (data['studentIds'] as List?)?.length ?? 0;
        return data;
      }).toList();
    } catch (e) {
      debugPrint("Error getting teacher classrooms: $e");
      return [];
    }
  }

  /// Join a classroom by ID and code. Returns null on success, error string on failure.
  Future<String?> joinClassroom(
    String studentId,
    String classroomId,
    String code,
  ) async {
    try {
      final doc = await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .get();
      if (!doc.exists) return "Classroom not found.";

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code']?.toString() ?? '';
      if (storedCode != code) return "Invalid classroom code.";

      // Check if already enrolled
      final studentIds = List<String>.from(data['studentIds'] ?? []);
      if (studentIds.contains(studentId)) {
        return "You are already in this class.";
      }

      // Add student to classroom
      await _firestore.collection('classrooms').doc(classroomId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });

      // Add classroomId to user's classroomIds array
      await _firestore.collection('users').doc(studentId).update({
        'classroomIds': FieldValue.arrayUnion([classroomId]),
      });

      return null; // Success
    } catch (e) {
      debugPrint("Error joining classroom: $e");
      return "Failed to join classroom: $e";
    }
  }

  /// Get all classrooms a student is enrolled in.
  Future<List<Map<String, dynamic>>> getStudentClassrooms(
    String studentId,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      if (!userDoc.exists) return [];

      final classroomIds = List<String>.from(
        userDoc.data()?['classroomIds'] ?? [],
      );
      if (classroomIds.isEmpty) return [];

      final classrooms = <Map<String, dynamic>>[];
      for (final id in classroomIds) {
        final classDoc = await _firestore
            .collection('classrooms')
            .doc(id)
            .get();
        if (classDoc.exists) {
          final data = classDoc.data() as Map<String, dynamic>;
          data['id'] = classDoc.id;
          data['studentCount'] = (data['studentIds'] as List?)?.length ?? 0;
          classrooms.add(data);
        }
      }
      return classrooms;
    } catch (e) {
      debugPrint("Error getting student classrooms: $e");
      return [];
    }
  }

  /// Leave a classroom.
  Future<void> leaveClassroom(String studentId, String classroomId) async {
    try {
      await _firestore.collection('classrooms').doc(classroomId).update({
        'studentIds': FieldValue.arrayRemove([studentId]),
      });
      await _firestore.collection('users').doc(studentId).update({
        'classroomIds': FieldValue.arrayRemove([classroomId]),
      });
    } catch (e) {
      debugPrint("Error leaving classroom: $e");
      rethrow;
    }
  }

  /// Get members (students) of a classroom with their display names.
  Future<List<Map<String, dynamic>>> getClassroomMembers(
    String classroomId,
  ) async {
    try {
      final classDoc = await _firestore
          .collection('classrooms')
          .doc(classroomId)
          .get();
      if (!classDoc.exists) return [];

      final studentIds = List<String>.from(
        classDoc.data()?['studentIds'] ?? [],
      );
      final members = <Map<String, dynamic>>[];
      for (final uid in studentIds) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          members.add({
            'uid': uid,
            'displayName': userDoc.data()?['displayName'] ?? 'Student',
            'form': userDoc.data()?['form'] ?? '',
          });
        }
      }
      return members;
    } catch (e) {
      debugPrint("Error getting classroom members: $e");
      return [];
    }
  }

  // ── Demo Seed ──

  /// Seeds a demo classroom with fake students for a teacher.
  /// Only runs once per teacher (checks for existing demo classroom).
  Future<void> seedDemoClassroom({
    required String teacherId,
    required String teacherName,
  }) async {
    try {
      // Check if demo classroom already exists
      final existing = await _firestore
          .collection('classrooms')
          .where('teacherId', isEqualTo: teacherId)
          .where('isDemo', isEqualTo: true)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint("Demo classroom already exists, skipping seed.");
        return;
      }

      debugPrint("Seeding demo classroom for $teacherName...");

      // 5 fake students
      final fakeStudents = [
        {'name': 'Aisha Binti Ahmad', 'form': 'Form 2'},
        {'name': 'Tan Wei Ming', 'form': 'Form 2'},
        {'name': 'Raj Kumar', 'form': 'Form 2'},
        {'name': 'Nurul Izzah', 'form': 'Form 2'},
        {'name': 'Lee Jia Wen', 'form': 'Form 2'},
      ];

      final studentIds = <String>[];

      for (final student in fakeStudents) {
        // Create fake user doc
        final userRef = _firestore.collection('users').doc();
        final uid = userRef.id;
        studentIds.add(uid);

        await userRef.set({
          'displayName': student['name'],
          'email':
              '${student['name']!.toLowerCase().replaceAll(' ', '.')}@demo.punca.ai',
          'form': student['form'],
          'role': 'student',
          'isDemo': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Create fake assessments for this student
        await _seedStudentAssessments(uid);
      }

      // Create the demo classroom
      await _firestore.collection('classrooms').add({
        'name': 'Form 2 Math (Demo)',
        'teacherId': teacherId,
        'teacherName': teacherName,
        'code': 'DEMO01',
        'studentIds': studentIds,
        'isDemo': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ Demo classroom seeded with ${studentIds.length} students.");
    } catch (e) {
      debugPrint("Error seeding demo classroom: $e");
    }
  }

  Future<void> _seedStudentAssessments(String studentId) async {
    final topics = [
      {
        'subject': 'Algebraic Expansion',
        'grade': '45',
        'gapType': 'foundation',
        'form': 2,
        'chapter': 3,
        'subtopic': 2,
      },
      {
        'subject': 'Factorisation',
        'grade': '62',
        'gapType': 'execution',
        'form': 2,
        'chapter': 4,
        'subtopic': 1,
      },
      {
        'subject': 'Linear Equations',
        'grade': '78',
        'gapType': 'precision',
        'form': 1,
        'chapter': 6,
        'subtopic': 1,
      },
      {
        'subject': 'Patterns & Sequences',
        'grade': '85',
        'gapType': 'precision',
        'form': 1,
        'chapter': 1,
        'subtopic': 5,
      },
      {
        'subject': 'Polygons',
        'grade': '70',
        'gapType': 'execution',
        'form': 1,
        'chapter': 11,
        'subtopic': 1,
      },
    ];

    // Pick 2-3 random assessments per student
    topics.shuffle();
    final count = 2 + (topics.length % 2); // 2 or 3
    final selected = topics.take(count);

    for (final t in selected) {
      // Save assessment
      await _assessments.add({
        'studentId': studentId,
        'subject': t['subject'],
        'grade': t['grade'],
        'imageUrls': [],
        'weaknesses': [
          {
            'topic': t['subject'],
            'reason': 'Needs more practice',
            'gap_type': t['gapType'],
            'action': 'Review chapter and do practice exercises',
            'priority': 5,
            'mistake_example': '2x + 3 = 7 → x = 3',
            'correction_example': '2x + 3 = 7 → 2x = 4 → x = 2',
            'syllabus_refs': [
              {
                'form': t['form'],
                'chapter': t['chapter'],
                'subtopic_id': t['subtopic'],
              },
            ],
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'isDemo': true,
      });

      // Save weakness to top-level collection for getGapAnalysis
      await _weaknesses.add({
        'studentId': studentId,
        'topic': t['subject'],
        'reason': 'Needs more practice',
        'gap_type': t['gapType'],
        'action': 'Review chapter',
        'isDemo': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
