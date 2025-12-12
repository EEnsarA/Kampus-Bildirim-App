import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//River Pod ref için Provider
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(auth: FirebaseAuth.instance), // arrow func =>
);

class AuthRepository {
  final FirebaseAuth auth;

  AuthRepository({required this.auth});

  Future<void> signIn({required String email, required String password}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    }
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  User? get currentUser => auth.currentUser;
}
