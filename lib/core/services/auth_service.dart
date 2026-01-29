import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validate current session
  User? get currentUser => _auth.currentUser;

  // Auth Change Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'Student' or 'Parent'
  }) async {
    try {
      print("Starting Sign Up for $email");
      // 1. Create User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("User created: ${result.user?.uid}");

      // 2. Create User Profile in Firestore
      if (result.user != null) {
        print("Creating Firestore document...");
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email,
          'displayName': name,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'linkedAccounts': [],
        });
        print("Firestore document created!");
        return null; // Success
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      print("AUTH ERROR: ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      print("UNKNOWN ERROR: $e");
      return e.toString();
    }
  }

  // Sign In
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
