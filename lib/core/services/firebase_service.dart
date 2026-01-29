import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; /* id: 0 */
import 'dart:io';

/* id: 2 */
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection References
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _assessments => _firestore.collection('assessments');
  CollectionReference get _weaknesses => _firestore.collection('weaknesses');

  /// "Uploads" an image (Simulated: Returns local path)
  Future<String?> uploadImage(String filePath, String fileName) async {
    // We are skipping Firebase Storage to avoid billing requirements.
    // Instead, we just return the local file path.
    // In a production app, you would upload this to a server.
    print("Using local file path for: $fileName");
    return filePath;
  }

  /// Saves the assessment result to Firestore
  Future<void> saveAssessment({
    required String studentId,
    required List<String> imageUrls,
    required Map<String, dynamic> aiAnalysis,
  }) async {
    try {
      await _assessments.add({
        'studentId': studentId,
        'imageUrls': imageUrls, // Store list of URLs
        'imageUrl': imageUrls.isNotEmpty
            ? imageUrls.first
            : null, // Legacy support/Thumbnail
        'aiAnalysis': aiAnalysis,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    } catch (e) {
      print('Error saving assessment: $e');
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
      batch.set(docRef, {
        'studentId': studentId,
        'topic': weakness['topic'] ?? 'Unknown',
        'reason': weakness['reason'] ?? '',
        'gap_type': weakness['gap_type'] ?? 'general',
        'confidenceScore': 50, // Default or parsed from analysis if available
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      print('Weaknesses batch committed successfully');
    } catch (e) {
      print('Error saving weaknesses: $e');
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
