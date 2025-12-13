import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//River Pod ref için Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.auth, required this.firestore});

  //login
  Future<void> signIn({required String email, required String password}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    }
  }

  //logout
  Future<void> signOut() async {
    await auth.signOut();
  }

  //Register
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String department,
    String role = "user", // default user
  }) async {
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      await firestore.collection("users").doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'surname': surname,
        'department': department,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Register error: $e");
    }
  }

  User? get currentUser => auth.currentUser;
}
