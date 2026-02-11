import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'package:flutter/foundation.dart';

/* id: 2 */
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseStorage _storage = FirebaseStorage.instance; // Unused

  // Collection References
  // CollectionReference get _users => _firestore.collection('users'); // Unused
  CollectionReference get _assessments => _firestore.collection('assessments');
  CollectionReference get _weaknesses => _firestore.collection('weaknesses');

  /// "Uploads" an image (Simulated: Returns local path)
  Future<String?> uploadImage(String filePath, String fileName) async {
    // We are skipping Firebase Storage to avoid billing requirements.
    // Instead, we just return the local file path.
    // In a production app, you would upload this to a server.

    FirebaseStorage.instance.ref().child(filePath + fileName);
    debugPrint("Using local file path for: $fileName");
    return filePath;
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
  /// If [subject] is null, returns breakdown by SUBJECT.
  Future<Map<String, double>> getMasteryStats(
    String studentId, {
    String? subject,
  }) async {
    try {
      final assessments = await getAssessments(studentId);

      Map<String, List<double>> keyScores = {};

      // 1. Pre-fill Syllabus for "Math" to show full grid
      if (subject == "Math") {
        KssmSyllabus.structure.forEach((form, chapters) {
          // DEMO LIMITATION: Only show Form 1 & 2 for now (Simulated "Form 2 Student")
          if (form <= 2) {
            for (var chap in chapters) {
              // "F1 C01: Title" format for sorting
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

      // Helper to find matching key in pre-filled list
      String? findMatchingKey(String topic) {
        // 1. Try exact match (ignoring "F1 C01: " prefix in keys)
        // keys are "F1 C01: Rational Numbers"
        // topic might be "Rational Numbers"
        for (var key in keyScores.keys) {
          if (key.endsWith(": $topic") ||
              key.toLowerCase().endsWith(": ${topic.toLowerCase()}")) {
            return key;
          }
        }
        // 2. Try partial/fuzzy?
        // Gemini might say "Integers" which is F1 C1 Subtopic 1.
        // For now, if no match, return generic topic name.
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
          } else {
            // Aggregate by TOPIC
            final topics = assessment.topics.isNotEmpty
                ? assessment.topics
                : ['General'];

            for (var topic in topics) {
              String key = topic;
              // Try to map to KSSM key if possible
              if (subject == "Math") {
                final match = findMatchingKey(topic);
                if (match != null) {
                  key = match;
                } else {
                  // Fallback: Check if it's already a key we added? (unlikely)
                  // Or just keep original string.
                  // Maybe prefix with "Misc: " to put at end?
                  // key = "Misc: $topic";
                }
              }

              if (!keyScores.containsKey(key)) {
                keyScores[key] = [];
              }
              keyScores[key]!.add(score);
            }
          }
        }
      }

      // Calculate Averages
      Map<String, double> mastery = {};
      keyScores.forEach((key, scores) {
        if (scores.isEmpty) {
          mastery[key] = 0.0; // Unattempted
        } else {
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          mastery[key] = avg / 100.0;
        }
      });

      // Sort keys (alphabetically, which works for "F1 C01..." format)
      final sortedKeys = mastery.keys.toList()..sort();
      final Map<String, double> sortedMastery = {
        for (var k in sortedKeys) k: mastery[k]!,
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
}
