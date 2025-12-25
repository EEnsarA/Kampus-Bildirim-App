import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

// Verilen imageyi firebase storage' ye yükleme
class StoreImgService {
  static Future<String?> uploadNotificationImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("notification_images")
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> uploadProfileImage(
    File imageFile,
    String userId,
  ) async {
    try {
      //  profile_images
      // Dosya adı 'userId.jpg' üzerine yazaıp yer kaplmaması için aynı
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_images")
          .child('$userId.jpg');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
