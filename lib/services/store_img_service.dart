/// =============================================================================
/// KAMPÜS BİLDİRİM - Resim Yükleme Servisi (store_img_service.dart)
/// =============================================================================
/// Bu dosya Firebase Storage'a resim yükleme işlemlerini yönetir.
/// Bildirim resimleri ve profil fotoğrafları için kullanılır.
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'dart:io'; // Dosya işlemleri için
import 'package:firebase_storage/firebase_storage.dart';

// =============================================================================
// StoreImgService Sınıfı
// =============================================================================
/// Firebase Storage'a resim yükleme işlemlerini gerçekleştirir.
/// Static metodlar kullanıldığı için instance oluşturmaya gerek yoktur.
class StoreImgService {
  // -------------------------------------------------------------------------
  // Bildirim Resmi Yükle
  // -------------------------------------------------------------------------
  /// Bildirime eklenecek resmi Storage'a yükler.
  ///
  /// Depolama Yolu: notification_images/{timestamp}.jpg
  /// Her resim benzersiz timestamp ile adlandırılır.
  ///
  /// Dönüş: Yüklenen resmin download URL'si (başarısızsa null)
  // -------------------------------------------------------------------------
  static Future<String?> uploadNotificationImage(File imageFile) async {
    try {
      // Storage referansı oluştur (benzersiz isimle)
      final ref = FirebaseStorage.instance
          .ref()
          .child("notification_images")
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Dosyayı yükle
      await ref.putFile(imageFile);

      // Download URL'sini döndür
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Profil Resmi Yükle
  // -------------------------------------------------------------------------
  /// Kullanıcı profil fotoğrafını Storage'a yükler.
  ///
  /// Depolama Yolu: profile_images/{userId}.jpg
  /// Aynı kullanıcının eski resmi üzerine yazılır (depolama tasarrufu).
  ///
  /// Dönüş: Yüklenen resmin download URL'si (başarısızsa null)
  // -------------------------------------------------------------------------
  static Future<String?> uploadProfileImage(
    File imageFile,
    String userId,
  ) async {
    try {
      // Storage referansı (userId ile - üzerine yazar)
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child('$userId.jpg');

      // Dosyayı yükle
      await ref.putFile(imageFile);

      // Download URL'sini döndür
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
