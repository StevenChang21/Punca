import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:punca_ai/core/models/assessment_model.dart';
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
}
