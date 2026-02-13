import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:punca_ai/firebase_options.dart';
import 'package:punca_ai/core/services/firebase_service.dart';
import 'package:punca_ai/core/services/auth_service.dart';

/// Integration test for the student-joins-classroom flow.
///
/// Run with (device must be connected):
///   flutter test integration_test/classroom_join_test.dart
///
/// This test uses REAL Firestore. It creates a classroom,
/// joins it as the current user, verifies, then cleans up.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseService firebaseService;
  late String testClassroomId;
  const testCode = 'TEST99';
  const testClassName = 'Integration Test Class';

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseService = FirebaseService();
  });

  group('Student Classroom Join Flow', () {
    testWidgets('1. Teacher creates a classroom', (tester) async {
      final uid = AuthService().currentUser?.uid;
      expect(uid, isNotNull, reason: 'You must be logged in to run this test');

      testClassroomId = await firebaseService.createClassroom(
        teacherId: uid!,
        teacherName: 'Test Teacher',
        className: testClassName,
        code: testCode,
      );

      expect(testClassroomId, isNotEmpty);
      debugPrint('✅ Created classroom: $testClassroomId with code: $testCode');
    });

    testWidgets('2. Join with WRONG code → error', (tester) async {
      final uid = AuthService().currentUser!.uid;

      final error = await firebaseService.joinClassroom(
        uid,
        testClassroomId,
        'WRONG1',
      );

      expect(error, isNotNull);
      expect(error, contains('Invalid'));
      debugPrint('✅ Wrong code correctly rejected: $error');
    });

    testWidgets('3. Join with CORRECT code → success', (tester) async {
      final uid = AuthService().currentUser!.uid;

      final error = await firebaseService.joinClassroom(
        uid,
        testClassroomId,
        testCode,
      );

      expect(error, isNull, reason: 'Join should succeed but got: $error');
      debugPrint('✅ Successfully joined classroom!');
    });

    testWidgets('4. Student classroom data is returned', (tester) async {
      final uid = AuthService().currentUser!.uid;

      final classroom = await firebaseService.getStudentClassroom(uid);

      expect(classroom, isNotNull);
      expect(classroom!['name'], equals(testClassName));
      expect(classroom['code'], equals(testCode));
      expect((classroom['studentIds'] as List), contains(uid));
      debugPrint('✅ Classroom data verified: ${classroom['name']}');
    });

    testWidgets('5. Cannot join same class again', (tester) async {
      final uid = AuthService().currentUser!.uid;

      final error = await firebaseService.joinClassroom(
        uid,
        testClassroomId,
        testCode,
      );

      expect(error, isNotNull);
      expect(error, contains('already'));
      debugPrint('✅ Duplicate join correctly rejected: $error');
    });

    testWidgets('6. Student leaves classroom', (tester) async {
      final uid = AuthService().currentUser!.uid;

      await firebaseService.leaveClassroom(uid, testClassroomId);

      final classroom = await firebaseService.getStudentClassroom(uid);
      expect(classroom, isNull);
      debugPrint('✅ Successfully left classroom');
    });

    testWidgets('7. Join with INVALID classroom ID → error', (tester) async {
      final uid = AuthService().currentUser!.uid;

      final error = await firebaseService.joinClassroom(
        uid,
        'nonexistent_classroom_id',
        testCode,
      );

      expect(error, isNotNull);
      expect(error, contains('not found'));
      debugPrint('✅ Invalid classroom ID correctly rejected: $error');
    });

    testWidgets('8. Cleanup: delete test classroom', (tester) async {
      await firebaseService.deleteClassroom(testClassroomId);
      debugPrint('🧹 Cleaned up test classroom: $testClassroomId');
    });
  });
}
