/// =============================================================================
/// KAMPÜS BİLDİRİM UYGULAMASI - Ana Giriş Noktası (main.dart)
/// =============================================================================
/// Bu dosya Flutter uygulamasının başlangıç noktasıdır.
/// Firebase servislerini başlatır ve FCM (Firebase Cloud Messaging) yapılandırır.
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

// Flutter temel kütüphanesi
import 'package:flutter/material.dart';

// Firebase servisleri
import 'package:firebase_core/firebase_core.dart'; // Firebase başlatma
import 'package:firebase_auth/firebase_auth.dart'; // Kullanıcı kimlik doğrulama
import 'package:cloud_firestore/cloud_firestore.dart'; // Veritabanı işlemleri
import 'package:firebase_messaging/firebase_messaging.dart'; // Push bildirimler

// State yönetimi
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Proje dosyaları
import 'package:kampus_bildirim/constants/app_colors.dart';
import 'package:kampus_bildirim/firebase_options.dart';
import 'package:kampus_bildirim/routes/app_router.dart';

/// Global ScaffoldMessenger anahtarı
/// SnackBar mesajlarını uygulama genelinde göstermek için kullanılır
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Arka plan mesaj işleyicisi
/// Uygulama kapalıyken gelen FCM mesajlarını işler
/// NOT: Bu fonksiyon top-level (sınıf dışında) olmalıdır
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Gelen mesajı logla (debug için)
  debugPrint('Arka plan FCM mesajı: ${message.notification?.title}');
}

/// Uygulamanın başlangıç fonksiyonu
/// Tüm servisleri başlatır ve ana widget'ı çalıştırır
void main() async {
  // Flutter widget binding'ini başlat (async işlemler için gerekli)
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase servislerini başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Arka plan mesaj işleyicisini kaydet
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Riverpod state yönetimi ile uygulamayı çalıştır
  runApp(const ProviderScope(child: MainApp()));
}

/// =============================================================================
/// MainApp - Ana Uygulama Widget'ı
/// =============================================================================
/// Uygulamanın kök widget'ıdır.
/// FCM yapılandırması ve auth state dinlemesi burada yapılır.
/// ConsumerStatefulWidget: Riverpod ile state yönetimi sağlar.
/// =============================================================================
class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();

    // FCM (Push bildirim) yapılandırmasını başlat
    _setupFCM();

    // Kullanıcı oturum değişikliklerini dinle
    _listenToAuthChanges();
  }

  /// ---------------------------------------------------------------------------
  /// Auth State Dinleyicisi
  /// ---------------------------------------------------------------------------
  /// Kullanıcının giriş/çıkış durumunu dinler.
  /// Giriş yapıldığında FCM token'ini Firestore'a kaydeder.
  /// ---------------------------------------------------------------------------
  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Kullanıcı giriş yaptı, FCM token'ı kaydet
        debugPrint('✅ Kullanıcı giriş yaptı: ${user.email}');
        _saveFcmToken();
      }
    });
  }

  /// ---------------------------------------------------------------------------
  /// FCM (Firebase Cloud Messaging) Yapılandırması
  /// ---------------------------------------------------------------------------
  /// Push bildirimleri için gerekli tüm ayarları yapar:
  /// 1. Bildirim izni ister
  /// 2. 'all' topic'ine abone olur (tüm kullanıcılar bu kanalı dinler)
  /// 3. FCM token'ini alır ve Firestore'a kaydeder
  /// 4. Ön plan ve arka plan mesaj dinleyicilerini kurar
  /// ---------------------------------------------------------------------------
  Future<void> _setupFCM() async {
    try {
      // 1. Bildirim izni iste
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true, // Bildirim gösterme izni
        badge: true, // Uygulama ikonunda sayı gösterme
        sound: true, // Ses çalma izni
        criticalAlert: true, // Acil bildirimler için
      );
      debugPrint('FCM İzin Durumu: ${settings.authorizationStatus}');

      // 2. 'all' topic'ine abone ol - tüm acil duyurular buradan gelir
      await FirebaseMessaging.instance.subscribeToTopic('all');
      debugPrint('✅ "all" topic\'ine abone olundu');

      // 3. FCM token'ini al ve kaydet
      await _saveFcmToken();

      // 4. Token yenilendiğinde otomatik güncelle
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _updateFcmTokenInFirestore(newToken);
      });

      // 5. Ön planda gelen mesajları dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Uygulama arka plandayken tıklanan bildirimleri dinle
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 7. Uygulama tamamen kapalıyken açılan bildirim
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ FCM yapılandırma hatası: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Ön Plan Mesaj İşleyicisi
  /// ---------------------------------------------------------------------------
  /// Uygulama açıkken gelen bildirimleri SnackBar olarak gösterir.
  /// Kullanıcı "Görüntüle" butonuna tıklayarak detay sayfasına gidebilir.
  /// ---------------------------------------------------------------------------
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // SnackBar ile bildirim göster
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

  /// ---------------------------------------------------------------------------
  /// Bildirime Tıklama İşleyicisi
  /// ---------------------------------------------------------------------------
  /// Kullanıcı bildirime tıkladığında ilgili detay sayfasına yönlendirir.
  /// ---------------------------------------------------------------------------
  void _handleMessageOpenedApp(RemoteMessage message) {
    // Mesaj verisinden bildirim ID'sini al
    final notificationId = message.data['notificationId'];

    // ID varsa detay sayfasına git
    if (notificationId != null && notificationId.isNotEmpty) {
      ref.read(routerProvider).push('/notification-detail/$notificationId');
    }
  }

  /// ---------------------------------------------------------------------------
  /// FCM Token Kaydetme
  /// ---------------------------------------------------------------------------
  /// Cihazın benzersiz FCM token'ini alır ve Firestore'a kaydeder.
  /// Bu token sayesinde kullanıcıya özel bildirimler gönderilebilir.
  /// ---------------------------------------------------------------------------
  Future<void> _saveFcmToken() async {
    try {
      // Giriş yapmış kullanıcıyı kontrol et
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ FCM Token: Kullanıcı giriş yapmamış');
        return;
      }

      // Token'i al ve kaydet
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _updateFcmTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('❌ FCM Token kaydetme hatası: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// FCM Token Güncelleme (Firestore)
  /// ---------------------------------------------------------------------------
  /// Token'i kullanıcının Firestore dokümanına yazar.
  /// Bu sayede Cloud Functions token'a erişebilir.
  /// ---------------------------------------------------------------------------
  Future<void> _updateFcmTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcı dokümanını güncelle
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token, 'fcmTokenUpdatedAt': FieldValue.serverTimestamp()},
      );

      // Debug için token'ın başını göster
      debugPrint('✅ FCM Token kaydedildi: ${token.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ FCM Token güncelleme hatası: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Build Metodu - Uygulama Arayüzü
  /// ---------------------------------------------------------------------------
  /// MaterialApp.router kullanarak uygulama temasını ve yönlendirmeyi ayarlar.
  /// ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Router provider'ı dinle
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // SnackBar mesajları için global anahtar
      scaffoldMessengerKey: scaffoldMessengerKey,

      // Uygulama başlığı
      title: 'Kampüs Bildirim',

      // Debug banner'ını gizle
      debugShowCheckedModeBanner: false,

      // Uygulama teması
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

      // Yönlendirme yapılandırması
      routerConfig: router,
    );
  }
}
