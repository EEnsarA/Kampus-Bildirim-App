import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Auth hata kodlarını kullanıcı dostu Türkçe mesajlara çevirir
String getFirebaseAuthErrorMessage(String code) {
  switch (code) {
    // Giriş hataları
    case 'user-not-found':
      return 'Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı.';
    case 'wrong-password':
      return 'Girdiğiniz şifre hatalı.';
    case 'invalid-credential':
      return 'E-posta veya şifre hatalı.';
    case 'invalid-email':
      return 'Geçersiz e-posta formatı.';
    case 'user-disabled':
      return 'Bu hesap devre dışı bırakılmış.';
    case 'too-many-requests':
      return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';

    // Kayıt hataları
    case 'email-already-in-use':
      return 'Bu e-posta adresi zaten kullanımda.';
    case 'weak-password':
      return 'Şifre çok zayıf. En az 6 karakter olmalı.';
    case 'operation-not-allowed':
      return 'E-posta/şifre girişi devre dışı.';

    // Şifre sıfırlama hataları
    case 'expired-action-code':
      return 'Şifre sıfırlama bağlantısının süresi dolmuş.';
    case 'invalid-action-code':
      return 'Şifre sıfırlama bağlantısı geçersiz.';

    // Ağ hataları
    case 'network-request-failed':
      return 'İnternet bağlantınızı kontrol edin.';

    default:
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

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
      throw Exception(getFirebaseAuthErrorMessage(e.code));
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
      throw Exception(getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Kayıt işlemi başarısız. Lütfen tekrar deneyin.');
    }
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilemedi.');
    }
  }

  User? get currentUser => auth.currentUser;
}
