import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kampus_bildirim/constants/app_colors.dart';
import 'package:kampus_bildirim/firebase_options.dart';
import 'package:kampus_bildirim/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Firebase Messaging and subscribe to topic 'all' for emergency broadcasts
    // Wrapped in try/catch so tests (which may not call Firebase.initializeApp) don't fail.
    try {
      FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.instance.subscribeToTopic('all');

      // Handle foreground messages (debug/log only)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Minimal handling: print for now; replace with local notification logic later
        // ignore: avoid_print
        print(
          'FCM message received: ${message.notification?.title} - ${message.notification?.body}',
        );
      });
    } catch (_) {
      // If Firebase isn't initialized (e.g., in widget tests), ignore FCM setup.
    }
    //navigation işlemleri için routerProvider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
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
