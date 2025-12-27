// app_router.dart - uygulama navigasyonu
// go_router paketi kullanıldı
// NOT: named routes de kullanabilirdik ama path based daha basit geldi

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/pages/add_notification_page.dart';
import 'package:kampus_bildirim/pages/admin_panel_page.dart';
import 'package:kampus_bildirim/pages/map_page.dart';
import 'package:kampus_bildirim/pages/notification_detail_page.dart';
import 'package:kampus_bildirim/pages/profile_page.dart';
import 'package:kampus_bildirim/pages/followed_notifications_page.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/splash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true, // debug için açık
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/add-notification',
        builder: (context, state) => const AddNotificationPage(),
      ),

      // ----- HARİTA -----
      /// extra parametresi ile belirli bir bildirime odaklanabilir
      GoRoute(
        path: "/map",
        builder: (context, state) {
          final notification = state.extra as AppNotification?;
          return MapPage(targetNotification: notification);
        },
      ),

      // ----- PROFİL -----
      GoRoute(
        path: "/profile",
        builder: (context, state) => const ProfilePage(),
      ),

      // ----- BİLDİRİM DETAY -----
      /// Path parameter: :id ile bildirim ID'si alınır
      GoRoute(
        path: "/notification-detail/:id",
        builder: (context, state) {
          final notificationId = state.pathParameters['id']!;
          return NotificationDetailPage(notificationId: notificationId);
        },
      ),

      // ----- TAKİP EDİLENLER -----
      GoRoute(
        path: '/followed',
        builder: (context, state) => const FollowedNotificationsPage(),
      ),

      // ----- ADMİN PANELİ -----
      GoRoute(
        path: "/admin",
        builder: (context, state) => const AdminPanelPage(),
      ),
    ],
  );
});
