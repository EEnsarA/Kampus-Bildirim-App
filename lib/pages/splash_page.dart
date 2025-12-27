/// =============================================================================
/// KAMPÜS BİLDİRİM - Açılış Ekranı (splash_page.dart)
/// =============================================================================
/// Bu dosya uygulama ilk açıldığında gösterilen yükleme ekranını içerir.
///
/// Görevleri:
/// - Logo ve yükleniyor göstergesi gösterme
/// - Firebase Auth durumunu dinleme
/// - Kullanıcı giriş yapmışsa ana sayfaya, yapmamışsa login'e yönlendirme
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

// =============================================================================
// SplashPage Widget'ı
// =============================================================================
/// Uygulama açılış ekranı.
/// ConsumerStatefulWidget - Riverpod state dinleme + Widget lifecycle.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // Auth State Dinleyicisi
    // -------------------------------------------------------------------------
    /// authStateProvider değiştiğinde bu listener tetiklenir.
    /// Kullanıcı durumuna göre yönlendirme yapar.
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            // Kullanıcı giriş yapmış -> Ana sayfa
            context.go('/home');
          } else {
            // Kullanıcı giriş yapmamış -> Login
            context.go('/login');
          }
        },
        loading: () {}, // Yükleniyor, bekle
        error: (err, stack) {
          // Hata durumunda login'e yönlendir
          context.go('/login');
        },
      );
    });

    // -------------------------------------------------------------------------
    // UI: Logo + Yükleniyor Göstergesi
    // -------------------------------------------------------------------------
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Uygulama logosu
            Image.asset("assets/images/logo.png", height: 120),
            SizedBox(height: 20),
            // Yükleniyor göstergesi
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Yükleniyor...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
