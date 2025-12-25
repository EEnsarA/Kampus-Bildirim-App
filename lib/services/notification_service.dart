import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> deleteNotification(String docId, String? imageUrl) async {
    try {
      await _firestore.collection('notifications').doc(docId).delete();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print("Resim silinirken hata oluştu : $e");
        }
      }
    } catch (e) {
      throw Exception("Bildirim silinemedi : $e");
    }
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());
