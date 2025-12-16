import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/pages/add_notification_page.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/splash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true, // İlk durak burası
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/add-notification',
        builder: (context, state) => const AddNotificationPage(),
      ),
    ],
  );
});
