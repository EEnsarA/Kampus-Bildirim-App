import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kampus_bildirim/constants/app_colors.dart';
import 'package:kampus_bildirim/firebase_options.dart';
import 'package:kampus_bildirim/routes/app_router.dart';

// Global navigator key for showing snackbars from anywhere
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background'da gelen mesajlar otomatik olarak sistem tarafından gösterilir
  debugPrint('Background FCM: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Background message handler'ı kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      // İzin iste
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );
      debugPrint('FCM Permission: ${settings.authorizationStatus}');

      // 'all' topic'ine subscribe ol
      await FirebaseMessaging.instance.subscribeToTopic('all');
      debugPrint('Subscribed to topic: all');

      // FCM token'ı al ve Firestore'a kaydet
      await _saveFcmToken();

      // Token yenilendiğinde tekrar kaydet
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _updateFcmTokenInFirestore(newToken);
      });

      // Foreground mesajlarını dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Uygulama kapalıyken tıklanan bildirimleri dinle
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Uygulama tamamen kapalıyken açılan bildirim
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Uygulama açıkken gelen bildirimi SnackBar ile göster
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notification.title ?? 'Bildirim',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (notification.body != null) ...[
              const SizedBox(height: 4),
              Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Görüntüle',
          textColor: Colors.white,
          onPressed: () {
            // Bildirim detayına git
            final notificationId = message.data['notificationId'];
            if (notificationId != null && notificationId.isNotEmpty) {
              ref
                  .read(routerProvider)
                  .push('/notification-detail/$notificationId');
            }
          },
        ),
      ),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Bildirime tıklanınca ilgili sayfaya yönlendir
    final notificationId = message.data['notificationId'];
    if (notificationId != null && notificationId.isNotEmpty) {
      ref.read(routerProvider).push('/notification-detail/$notificationId');
    }
  }

  /// FCM token'ı al ve Firestore'a kaydet
  Future<void> _saveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('FCM Token: Kullanıcı giriş yapmamış');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _updateFcmTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('FCM Token kaydetme hatası: $e');
    }
  }

  /// FCM token'ı Firestore'daki kullanıcı dokümanına kaydet
  Future<void> _updateFcmTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      );
      debugPrint('FCM Token kaydedildi: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('FCM Token güncelleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Kampüs Bildirim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      routerConfig: router,
    );
  }
}
