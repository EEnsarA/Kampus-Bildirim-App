/// =============================================================================
/// KAMPÜS BİLDİRİM - Kimlik Doğrulama Servisi (auth_service.dart)
/// =============================================================================
/// Bu dosya Repository ve UI arasındaki servis katmanını oluşturur.
///
/// NEDEN SERVİS KATMANI?
/// İleride veritabanı veya authentication yöntemi değişirse:
/// - Sadece Repository değiştirilir
/// - Service ve UI dokunulmaz
/// Bu sayede kod bakımı kolaylaşır (Separation of Concerns prensibi)
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/repository/auth_repository.dart';

// =============================================================================
// AUTH SERVICE PROVIDER
// =============================================================================
/// Riverpod provider - dependency injection için
final authServiceProvider = Provider<AuthService>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthService(authRepository: repo);
});

// =============================================================================
// AuthService Sınıfı
// =============================================================================
/// Repository'ye erişimi soyutlayan servis sınıfı.
/// UI bu sınıf aracılığıyla auth işlemlerini gerçekleştirir.
class AuthService {
  /// Repository bağımlılığı (Dependency Injection)
  final AuthRepository authRepository;

  /// Constructor
  AuthService({required this.authRepository});

  // -------------------------------------------------------------------------
  // Giriş Yap
  // -------------------------------------------------------------------------
  /// E-posta ve şifre ile oturum açar.
  Future<void> signIn({required String email, required String password}) async {
    return authRepository.signIn(email: email, password: password);
  }

  // -------------------------------------------------------------------------
  // Kayıt Ol
  // -------------------------------------------------------------------------
  /// Yeni kullanıcı kaydı oluşturur.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String department,
  }) async {
    return authRepository.register(
      email: email,
      password: password,
      name: name,
      surname: surname,
      department: department,
      role: 'user', // Varsayılan rol
    );
  }

  // -------------------------------------------------------------------------
  // Çıkış Yap
  // -------------------------------------------------------------------------
  /// Mevcut oturumu sonlandırır.
  Future<void> signOut() async {
    return authRepository.signOut();
  }

  // -------------------------------------------------------------------------
  // Şifre Sıfırlama
  // -------------------------------------------------------------------------
  /// Verilen e-posta adresine şifre sıfırlama bağlantısı gönderir.
  Future<void> sendPasswordResetEmail({required String email}) async {
    return authRepository.sendPasswordResetEmail(email: email);
  }
}
