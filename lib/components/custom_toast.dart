/// =============================================================================
/// KAMPÜS BİLDİRİM - Özel Toast Bileşeni (custom_toast.dart)
/// =============================================================================
/// Bu dosya ekranın üst kısmında gösterilen özel bildirim mesajlarını içerir.
/// Flutter'ın varsayılan SnackBar'ı yerine daha şık bir tasarım sunar.
///
/// Kullanım: showCustomToast(context, "Mesaj", isError: true/false)
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter/material.dart';
import 'dart:async'; // Future.delayed için

// =============================================================================
// showCustomToast Fonksiyonu
// =============================================================================
/// Ekranın üstünde geçici bir bildirim mesajı gösterir.
///
/// Parametreler:
/// - context: Uygulamanın mevcut context'i
/// - message: Gösterilecek mesaj metni
/// - isError: true ise kırmızı, false ise yeşil görünür
///
/// Çalışma Prensibi:
/// 1. Overlay kullanarak UI'ın üzerine widget ekler
/// 2. 3 saniye sonra otomatik olarak kaybolur
/// 3. Positioned ile ekranın üst kısmına yerleştirilir
void showCustomToast(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  // Overlay state'ini al
  OverlayState? overlayState = Overlay.of(context);

  late OverlayEntry overlayEntry;

  // Overlay entry oluştur
  overlayEntry = OverlayEntry(
    builder:
        (context) => Positioned(
          // Ekranın safe area'sı + 10px aşağıda
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          // Material widget - Overlay'de shadow çalışması için gerekli
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // Hata ise kırmızı, değilse yeşil
                color: isError ? Colors.redAccent : Colors.green,
                borderRadius: BorderRadius.circular(12),
                // Gölge efekti
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hata/Başarı ikonu
                  Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  // Mesaj metni
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  // Overlay'e ekle
  overlayState.insert(overlayEntry);

  // 3 saniye sonra kaldır
  Future.delayed(const Duration(seconds: 3), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}
