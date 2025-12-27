// auth_service.dart
// Neden service içerisinde her şeyi yapmak varken repository olarak ayrıldı ?
// Çünkü ileride database , database yöntemi değişirse sadece repo değişilir.
// Bu sayede baştan service yazmak zorunda kalınmaz . Özellikle büyük projelerde mimari .
// TODO: belki şifre değiştirme de eklerim buraya

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/repository/auth_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthService(authRepository: repo);
});

/// Repository'ye erişimi soyutlayan servis sınıfı
class AuthService {
  final AuthRepository authRepository;

  AuthService({required this.authRepository});

  // login
  Future<void> signIn({required String email, required String password}) async {
    return authRepository.signIn(email: email, password: password);
  }

  // register
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
      role: 'user',
    );
  }

  // logout
  Future<void> signOut() async {
    return authRepository.signOut();
  }

  /// Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail({required String email}) async {
    return authRepository.sendPasswordResetEmail(email: email);
  }
}
