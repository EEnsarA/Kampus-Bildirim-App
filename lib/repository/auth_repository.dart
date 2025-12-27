/// =============================================================================
/// KAMPÜS BİLDİRİM - Kimlik Doğrulama Repository (auth_repository.dart)
/// =============================================================================
/// Bu dosya Firebase Authentication ile ilgili tüm veritabanı işlemlerini içerir.
/// Repository pattern: Veri erişim katmanını soyutlar.
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// FİREBASE AUTH HATA ÇEVİRİCİSİ
// =============================================================================
/// Firebase Auth hata kodlarını kullanıcı dostu Türkçe mesajlara çevirir.
///
/// Parametreler:
/// - code: Firebase'den gelen hata kodu (orn: 'user-not-found')
///
/// Dönüş: Kullanıcıya gösterilecek Türkçe hata mesajı
String getFirebaseAuthErrorMessage(String code) {
  switch (code) {
    // ----- Giriş Hataları -----
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

    // ----- Kayıt Hataları -----
    case 'email-already-in-use':
      return 'Bu e-posta adresi zaten kullanımda.';
    case 'weak-password':
      return 'Şifre çok zayıf. En az 6 karakter olmalı.';
    case 'operation-not-allowed':
      return 'E-posta/şifre girişi devre dışı.';

    // ----- Şifre Sıfırlama Hataları -----
    case 'expired-action-code':
      return 'Şifre sıfırlama bağlantısının süresi dolmuş.';
    case 'invalid-action-code':
      return 'Şifre sıfırlama bağlantısı geçersiz.';

    // ----- Ağ Hataları -----
    case 'network-request-failed':
      return 'İnternet bağlantınızı kontrol edin.';

    // ----- Varsayılan -----
    default:
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}

// =============================================================================
// AUTH REPOSITORY PROVIDER
// =============================================================================
/// Riverpod provider - dependency injection için
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

// =============================================================================
// AuthRepository Sınıfı
// =============================================================================
/// Kimlik doğrulama işlemlerini yöneten repository sınıfı.
///
/// İçerdiği İşlemler:
/// - Giriş (signIn)
/// - Kayıt (register)
/// - Çıkış (signOut)
/// - Şifre sıfırlama (sendPasswordResetEmail)
// =============================================================================
class AuthRepository {
  // Firebase servisleri (Dependency Injection ile alınır)
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  /// Constructor - Firebase servislerini dışarıdan alır (test edilebilirlik için)
  AuthRepository({required this.auth, required this.firestore});

  // -------------------------------------------------------------------------
  // Giriş Yap
  // -------------------------------------------------------------------------
  /// E-posta ve şifre ile kullanıcı girişi yapar.
  /// Hata durumunda Türkçe hata mesajı fırlatır.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(getFirebaseAuthErrorMessage(e.code));
    }
  }

  // -------------------------------------------------------------------------
  // Çıkış Yap
  // -------------------------------------------------------------------------
  /// Mevcut oturumu sonlandırır.
  Future<void> signOut() async {
    await auth.signOut();
  }

  // -------------------------------------------------------------------------
  // Kayıt Ol
  // -------------------------------------------------------------------------
  /// Yeni kullanıcı kaydı oluşturur.
  ///
  /// İşlem Adımları:
  /// 1. Firebase Auth'da kullanıcı oluştur
  /// 2. Firestore'da kullanıcı profili dokümanı oluştur
  ///
  /// Parametreler:
  /// - email, password: Kimlik bilgileri
  /// - name, surname: Kişisel bilgiler
  /// - department: Birim/Bölüm
  /// - role: Varsayılan 'user', admin ataması manuel yapılır
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String department,
    String role = "user",
  }) async {
    try {
      // 1. Firebase Auth'da kullanıcı oluştur
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      // 2. Firestore'da profil dokümanı oluştur
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

  // -------------------------------------------------------------------------
  // Şifre Sıfırlama
  // -------------------------------------------------------------------------
  /// Verilen e-posta adresine şifre sıfırlama bağlantısı gönderir.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilemedi.');
    }
  }

  // -------------------------------------------------------------------------
  // Mevcut Kullanıcı Getter'ı
  // -------------------------------------------------------------------------
  /// Şu anda giriş yapmış kullanıcıyı döndürür (null olabilir).
  User? get currentUser => auth.currentUser;
}
