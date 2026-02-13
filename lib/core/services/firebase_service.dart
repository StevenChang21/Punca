import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
import 'package:punca_ai/core/constants/kssm_syllabus.dart';
import 'package:punca_ai/core/models/syllabus_model.dart';
import 'package:flutter/foundation.dart';

/* id: 3 */
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

        if (gapType == 'foundation')
          foundation++;
        else if (gapType == 'execution')
          execution++;
        else if (gapType == 'precision')
          precision++;
        else
          execution++; // Default general to execution for now

        total++;
      }

      if (total == 0)
        return {'foundation': 0.33, 'execution': 0.33, 'precision': 0.34};

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
}
