import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/repository/auth_repository.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthService(authRepository: repo);
});

class AuthService {
  final AuthRepository authRepository;

  AuthService({required this.authRepository});

  //login
  Future<void> signIn({required String email, required String password}) async {
    return authRepository.signIn(email: email, password: password);
  }

  //register
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

  //logout
  Future<void> signOut() async {
    return authRepository.signOut();
  }
}
