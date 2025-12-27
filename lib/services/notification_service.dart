/// =============================================================================
/// KAMPÜS BİLDİRİM - Bildirim Servisi (notification_service.dart)
/// =============================================================================
/// Bu dosya bildirimlerle ilgili ek servis işlemlerini içerir.
/// Özellikle resim silme gibi storage işlemleri burada yönetilir.
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// NotificationService Sınıfı
// =============================================================================
/// Bildirim silme ve resim yönetimi işlemlerini gerçekleştirir.
class NotificationService {
  /// Firebase servisleri
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // -------------------------------------------------------------------------
  // Bildirim ve Resmini Sil
  // -------------------------------------------------------------------------
  /// Bildirimi Firestore'dan siler.
  /// Eğer bildirime ekli resim varsa Storage'dan da siler.
  ///
  /// Parametreler:
  /// - docId: Silinecek bildirim doküman ID'si
  /// - imageUrl: Bildirime ait resim URL'si (opsiyonel)
  // -------------------------------------------------------------------------
  Future<void> deleteNotification(String docId, String? imageUrl) async {
    try {
      // 1. Firestore'dan bildirimi sil
      await _firestore.collection('notifications').doc(docId).delete();

      // 2. Eğer resim varsa Storage'dan sil
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          // Resim silme hatası ana işlemi engellemez
          print("Resim silinirken hata oluştu: $e");
        }
      }
    } catch (e) {
      throw Exception("Bildirim silinemedi: $e");
    }
  }
}

// =============================================================================
// PROVIDER
// =============================================================================
/// Riverpod provider - dependency injection için
final notificationServiceProvider = Provider((ref) => NotificationService());
