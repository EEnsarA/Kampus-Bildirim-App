/// =============================================================================
/// KAMPÜS BİLDİRİM - Uygulama Renkleri (app_colors.dart)
/// =============================================================================
/// Bu dosya uygulama genelinde kullanılan sabit renkleri tanımlar.
///
/// NEDEN SABIT RENKLER?
/// - Tutarlılık: Tüm ekranlarda aynı renkler kullanılır
/// - Bakım kolaylığı: Renk değiştirmek için tek yer
/// - Tema uyumu: Material Design prensiplerine uygun
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter/widgets.dart';

// =============================================================================
// AppColors Sınıfı
// =============================================================================
/// Uygulama renk paleti.
/// Tüm renkler static const olarak tanımlanır.
class AppColors {
  /// Ana renk - AppBar, butonlar, vurgular için
  /// Koyu mor tonlarında
  static const Color primaryColor = Color.fromARGB(240, 41, 37, 89);

  /// İkincil renk - İkonlar, alt vurgular için
  /// Koyu lacivert tonlarında
  static const Color secondaryColor = Color.fromARGB(250, 18, 35, 51);

  /// Arka plan rengi - Scaffold background
  /// Açık gri
  static const Color backgroundPrimary = Color(0xFFF5F5F5);
}
