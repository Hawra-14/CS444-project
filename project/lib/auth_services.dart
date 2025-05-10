import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': username,
        'email': email,
        'role': 'customer',
      });
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already in use.';
      } else if (e.code == 'invalid-email') {
        return 'This email address is invalid.';
      } else if (e.code == 'weak-password') {
        return 'The password is too weak.';
      } else {
        return 'Authentication error: ${e.message}';
      }
    } catch (e) {
      return 'Unexpected error: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists || !userDoc.data()!.containsKey('role')) {
        return {'error': 'User role not found'};
      }
      final role = userDoc['role'] as String;
      return {'role': role};
    } on FirebaseAuthException catch (e) {
      return {'error': e.message ?? 'Authentication failed'};
    } catch (e) {
      return {'error': 'Unexpected error: ${e.toString()}'};
    }
  }
}
