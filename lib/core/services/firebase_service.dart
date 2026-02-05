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

  /// Saves the assessment result to Firestore
  Future<void> saveAssessment(AssessmentResult result) async {
    try {
      await _assessments.add(result.toMap()); // Use cleaner toMap() method

      // Save weaknesses in batch (handled automatically if we want, or keeping separate logic inside if needed)
      // Since toMap() includes 'weaknesses' as a nested list map, Firestore stores it as an array of objects.
      // But if we want the top-level 'weaknesses' collection for querying:
      if (result.weaknesses.isNotEmpty) {
        await saveWeaknesses(
          studentId: result.studentId,
          weaknesses: result.weaknesses.map((w) => w.toMap()).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error saving assessment: $e');
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

  /// Stream of assessments for a specific student
  Stream<QuerySnapshot> getStudentAssessments(String studentId) {
    return _assessments
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
