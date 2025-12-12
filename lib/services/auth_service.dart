import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/repository/auth_repository.dart';

final authServiceProvider = Provider(
  (ref) => AuthService(authRepository: ref.watch(authRepositoryProvider)),
);

class AuthService {
  final AuthRepository authRepository;

  AuthService({required this.authRepository});

  Future<void> signIn({required String email, required String password}) async {
    return authRepository.signIn(email: email, password: password);
  }
}
