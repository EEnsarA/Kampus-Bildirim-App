// store_img_service.dart
// firebase storage'a resim yükleme

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StoreImgService {
  /// Bildirim resmi yükle
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
