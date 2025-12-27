/// =============================================================================
/// KAMPÜS BİLDİRİM - Bildirim Repository (notification_repository.dart)
/// =============================================================================
/// Bu dosya Firestore veritabanı ile bildirim CRUD işlemlerini yönetir.
/// Repository pattern: Veri erişim katmanını UI'dan soyutlar.
///
/// İçerdiği İşlemler:
/// - Bildirim listeleme (Stream)
/// - Bildirim oluşturma
/// - Durum güncelleme
/// - Takip etme/bırakma
/// - Arama ve filtreleme
/// - Admin işlemleri (silme, acil duyuru)
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

// =============================================================================
// NOTIFICATION REPOSITORY PROVIDER
// =============================================================================
/// Riverpod provider - dependency injection için
/// Uygulama genelinde tek instance kullanılır (Singleton pattern)
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: FirebaseFirestore.instance);
});

// =============================================================================
// NotificationRepository Sınıfı
// =============================================================================
/// Bildirimlerle ilgili tüm veritabanı işlemlerini yönetir.
class NotificationRepository {
  /// Firestore instance (Dependency Injection ile alınır)
  final FirebaseFirestore firestore;

  /// Constructor
  NotificationRepository({required this.firestore});

  // -------------------------------------------------------------------------
  // Collection Referansı
  // -------------------------------------------------------------------------
  /// 'notifications' collection'una referans döndürür.
  CollectionReference get _notificationsCollection =>
      firestore.collection('notifications');

  // =========================================================================
  // LİSTELEME İŞLEMLERİ
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Tüm Bildirimleri Getir (Stream)
  /// ---------------------------------------------------------------------------
  /// Tüm bildirimleri gerçek zamanlı olarak dinler.
  /// - Tarihe göre azalan sıralama (en yeni önce)
  /// - Silinmiş (soft-delete) bildirimler filtrelenir
  /// ---------------------------------------------------------------------------
  Stream<List<AppNotification>> getAllNotificationsStream() {
    return _notificationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .where((n) => n.isDeleted == false) // Silinmişleri filtrele
              .toList();
        });
  }

  // =========================================================================
  // ADMİN SİLME İŞLEMLERİ
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Soft-Delete (Geçici Silme)
  /// ---------------------------------------------------------------------------
  /// Bildirimi kalıcı olarak silmez, sadece 'isDeleted' flag'ini true yapar.
  /// Bu sayede gerektiğinde geri getirilebilir.
  /// ---------------------------------------------------------------------------
  Future<void> softDeleteNotification(
    String notificationId, {
    String? adminId,
    String? adminName,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Admin işlemi logla (denetim için)
      await _logAdminAction(
        adminId: adminId,
        adminName: adminName,
        action: 'soft_delete',
        notificationId: notificationId,
        details: null,
      );
    } catch (e) {
      throw Exception('Bildirim silinemedi (soft-delete): $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Silinen Bildirimi Geri Getir
  /// ---------------------------------------------------------------------------
  /// Soft-delete ile silinen bildirimi tekrar aktif hale getirir.
  /// ---------------------------------------------------------------------------
  Future<void> restoreNotification(
    String notificationId, {
    String? adminId,
    String? adminName,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isDeleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Admin işlemi logla
      await _logAdminAction(
        adminId: adminId,
        adminName: adminName,
        action: 'restore',
        notificationId: notificationId,
        details: null,
      );
    } catch (e) {
      throw Exception('Bildirim geri getirilemedi: $e');
    }
  }

  // =========================================================================
  // TEKLİ BİLDİRİM GETİRME
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// ID ile Bildirim Getir
  /// ---------------------------------------------------------------------------
  /// Verilen ID'ye sahip bildirimi Firestore'dan çeker.
  /// Bulunamazsa null döndürür.
  /// ---------------------------------------------------------------------------
  Future<AppNotification?> getNotificationById(String notificationId) async {
    try {
      final doc = await _notificationsCollection.doc(notificationId).get();
      if (doc.exists) {
        return AppNotification.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Bildirim alınamadı: $e');
    }
  }

  // =========================================================================
  // BİLDİRİM OLUŞTURMA
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Yeni Bildirim Oluştur
  /// ---------------------------------------------------------------------------
  /// Kullanıcıların yeni bildirim göndermesi için kullanılır.
  /// Oluşturulan dokümanın ID'sini döndürür.
  /// ---------------------------------------------------------------------------
  Future<String> createNotification({
    required String title,
    required String content,
    required NotificationType type,
    required double latitude,
    required double longitude,
    required String senderId,
    required String senderName,
    required String department,
    String? imageUrl,
  }) async {
    try {
      final docRef = await _notificationsCollection.add({
        'title': title,
        'content': content,
        'type': type.name,
        'status': NotificationStatus.open.name, // Varsayılan durum: Açık
        'latitude': latitude,
        'longitude': longitude,
        'senderId': senderId,
        'senderName': senderName,
        'department': department,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'followedBy': [], // Takipçi listesi (başlangıçta boş)
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Bildirim oluşturulamadı: $e');
    }
  }

  // =========================================================================
  // DURUM GÜNCELLEME (ADMİN)
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Bildirim Durumunu Güncelle
  /// ---------------------------------------------------------------------------
  /// Admin tarafından bildirim durumunu değiştirir.
  /// Durum değişikliğinde takipçilere FCM bildirimi gönderilir.
  ///
  /// İşlem Adımları:
  /// 1. Mevcut bildirimi ve takipçileri al
  /// 2. Durumu güncelle
  /// 3. Admin işlemini logla
  /// 4. fcm_messages'a yaz (Cloud Function tetikler)
  /// ---------------------------------------------------------------------------
  Future<void> updateNotificationStatus({
    required String notificationId,
    required NotificationStatus newStatus,
    String? adminId,
    String? adminName,
  }) async {
    try {
      // 1. Mevcut bildirimi al (eski durum ve takipçiler için)
      final doc = await _notificationsCollection.doc(notificationId).get();
      if (!doc.exists) {
        throw Exception('Bildirim bulunamadı');
      }

      final data = doc.data() as Map<String, dynamic>;
      final oldStatus = data['status'] ?? 'open';
      final followers = List<String>.from(data['followedBy'] ?? []);
      final notificationTitle = data['title'] ?? 'Bildirim';

      // 2. Durumu güncelle
      await _notificationsCollection.doc(notificationId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Admin işlemini logla
      if (adminId != null || adminName != null) {
        await _logAdminAction(
          adminId: adminId,
          adminName: adminName,
          action: 'update_status',
          notificationId: notificationId,
          details: {'oldStatus': oldStatus, 'newStatus': newStatus.name},
        );
      }

      // 4. Takipçilere bildirim gönder (FCM)
      // fcm_messages collection'a yazılarak Cloud Function tetiklenir
      if (followers.isNotEmpty && oldStatus != newStatus.name) {
        final statusLabels = {
          'open': 'Açık',
          'reviewing': 'İnceleniyor',
          'resolved': 'Çözüldü',
        };
        final newStatusLabel = statusLabels[newStatus.name] ?? newStatus.name;

        debugPrint('📢 FCM mesajı yazılıyor - Takipçiler: $followers');
        await firestore.collection('fcm_messages').add({
          'notificationId': notificationId,
          'title': '📢 Durum Güncellendi',
          'content':
              '"$notificationTitle" bildirimi artık "$newStatusLabel" durumunda.',
          'type': 'status_update',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM mesajı başarıyla yazıldı');
      } else {
        debugPrint(
          '⚠️ FCM mesajı yazılmadı - Takipçi: ${followers.length}, Durum değişti mi: ${oldStatus != newStatus.name}',
        );
      }
    } catch (e) {
      debugPrint('❌ Durum güncelleme hatası: $e');
      throw Exception('Bildirim durumu güncellenemedi: $e');
    }
  }

  // =========================================================================
  // İÇERİK GÜNCELLEME (ADMİN)
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Bildirim İçeriğini Güncelle
  /// ---------------------------------------------------------------------------
  /// Admin tarafından bildirim açıklamasını düzenler.
  /// ---------------------------------------------------------------------------
  Future<void> updateNotificationContent({
    required String notificationId,
    required String content,
    String? adminId,
    String? adminName,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Admin işlemini logla
      if (adminId != null || adminName != null) {
        await _logAdminAction(
          adminId: adminId,
          adminName: adminName,
          action: 'update_content',
          notificationId: notificationId,
          details: {'contentLength': content.length},
        );
      }
    } catch (e) {
      throw Exception('Bildirim içeriği güncellenemedi: $e');
    }
  }

  // =========================================================================
  // TAKİP İŞLEMLERİ
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Bildirimi Takip Et
  /// ---------------------------------------------------------------------------
  /// Kullanıcıyı bildirimin 'followedBy' listesine ekler.
  /// Durum değişikliklerinde kullanıcı bildirim alır.
  /// ---------------------------------------------------------------------------
  Future<void> followNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      // Firestore arrayUnion: Diziye eleman ekler (varsa eklemez)
      await _notificationsCollection.doc(notificationId).update({
        'followedBy': FieldValue.arrayUnion([userId]),
      });

      // Kullanıcı işlemini logla (denetim için)
      await _logAdminAction(
        adminId: userId,
        adminName: null,
        action: 'follow',
        notificationId: notificationId,
        details: null,
      );
    } catch (e) {
      throw Exception('Bildirim takibi yapılamadı: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Bildirimi Takipten Çıkar
  /// ---------------------------------------------------------------------------
  /// Kullanıcıyı bildirimin 'followedBy' listesinden çıkarır.
  /// ---------------------------------------------------------------------------
  Future<void> unfollowNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      // Firestore arrayRemove: Diziden eleman çıkarır
      await _notificationsCollection.doc(notificationId).update({
        'followedBy': FieldValue.arrayRemove([userId]),
      });

      // Kullanıcı işlemini logla
      await _logAdminAction(
        adminId: userId,
        adminName: null,
        action: 'unfollow',
        notificationId: notificationId,
        details: null,
      );
    } catch (e) {
      throw Exception('Bildirim takibi kaldırılamadı: $e');
    }
  }

  /// ---------------------------------------------------------------------------
  /// Takip Edilen Bildirimleri Getir (Stream)
  /// ---------------------------------------------------------------------------
  /// Kullanıcının takip ettiği bildirimleri gerçek zamanlı dinler.
  /// Firestore 'arrayContains' sorgusu kullanır.
  /// ---------------------------------------------------------------------------
  Stream<List<AppNotification>> getFollowedNotificationsStream(String userId) {
    return _notificationsCollection
        .where('followedBy', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  // =========================================================================
  // FİLTRELEME İŞLEMLERİ
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Türe Göre Filtrele
  /// ---------------------------------------------------------------------------
  /// Belirli bir türdeki bildirimleri getirir.
  /// Örn: Sadece acil durumları veya etkinlikleri listele.
  /// ---------------------------------------------------------------------------
  Stream<List<AppNotification>> getNotificationsByType(NotificationType type) {
    return _notificationsCollection
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  /// ---------------------------------------------------------------------------
  /// Duruma Göre Filtrele
  /// ---------------------------------------------------------------------------
  /// Belirli bir durumdaki bildirimleri getirir.
  /// Örn: Sadece açık veya çözülmüş bildirimleri listele.
  /// ---------------------------------------------------------------------------
  Stream<List<AppNotification>> getNotificationsByStatus(
    NotificationStatus status,
  ) {
    return _notificationsCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }

  // =========================================================================
  // ARAMA İŞLEMİ
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Başlık ve İçerikle Ara
  /// ---------------------------------------------------------------------------
  /// Verilen sorguyu başlık ve içerikte arar.
  ///
  /// NOT: Firestore full-text search desteklemediği için
  /// tüm veriler çekilip client-side filtreleme yapılır.
  /// Büyük veri setlerinde performans sorunu olabilir.
  /// ---------------------------------------------------------------------------
  Future<List<AppNotification>> searchNotifications(String query) async {
    try {
      // Tüm bildirimleri çek
      final snapshot = await _notificationsCollection.get();
      final allNotifications =
          snapshot.docs
              .map(
                (doc) => AppNotification.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Client-side filtreleme (küçük harfe çevirerek)
      return allNotifications.where((notification) {
        final queryLower = query.toLowerCase();
        return notification.title.toLowerCase().contains(queryLower) ||
            notification.content.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      throw Exception('Arama yapılamadı: $e');
    }
  }

  // =========================================================================
  // KALICI SİLME (ADMİN)
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Bildirimi Kalıcı Olarak Sil
  /// ---------------------------------------------------------------------------
  /// Bildirimi Firestore'dan tamamen siler.
  /// DİKKAT: Bu işlem geri alınamaz! Soft-delete tercih edilmeli.
  /// ---------------------------------------------------------------------------
  Future<void> deleteNotification(
    String notificationId, {
    String? adminId,
    String? adminName,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();

      // Silme işlemini logla
      await _logAdminAction(
        adminId: adminId,
        adminName: adminName,
        action: 'delete_notification',
        notificationId: notificationId,
        details: null,
      );
    } catch (e) {
      throw Exception('Bildirim silinemedi: $e');
    }
  }

  // =========================================================================
  // ACİL DUYURU (ADMİN)
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Acil Bildirim Yayınla
  /// ---------------------------------------------------------------------------
  /// Admin tarafından acil duyuru oluşturur ve tüm kullanıcılara FCM gönderir.
  ///
  /// İşlem Adımları:
  /// 1. Acil bildirim dokümanı oluştur
  /// 2. Admin işlemini logla
  /// 3. fcm_messages'a yaz (Cloud Function FCM gönderir)
  /// ---------------------------------------------------------------------------
  Future<String> createEmergencyNotification({
    required String title,
    required String content,
    required String adminId,
    required String adminName,
    double latitude = 39.9042, // Varsayılan: kampüs merkezi
    double longitude = 32.8642,
  }) async {
    try {
      // 1. Acil bildirim dokümanı oluştur
      final docRef = await _notificationsCollection.add({
        'title': title,
        'content': content,
        'type': NotificationType.emergency.name,
        'status': NotificationStatus.open.name,
        'latitude': latitude,
        'longitude': longitude,
        'senderId': adminId,
        'senderName': adminName,
        'department': 'YÖNETİM',
        'imageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'followedBy': [],
        'isEmergency': true, // Acil durum flag'i
      });

      // 2. Admin işlemini logla
      await _logAdminAction(
        adminId: adminId,
        adminName: adminName,
        action: 'create_emergency',
        notificationId: docRef.id,
        details: {'title': title},
      );

      // 3. Cloud Function'u tetiklemek için fcm_messages'a yaz
      await firestore.collection('fcm_messages').add({
        'notificationId': docRef.id,
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Acil bildirim yayınlanamadı: $e');
    }
  }

  // =========================================================================
  // DENETİM LOGLAMA (PRİVATE)
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// Admin İşlemini Logla
  /// ---------------------------------------------------------------------------
  /// Tüm admin işlemlerini 'admin_actions' collection'una kaydeder.
  /// Denetim ve güvenlik amaçlı kullanılır.
  ///
  /// NOT: Loglama hatası ana işlemi engellemez (sessizce geçilir).
  /// ---------------------------------------------------------------------------
  Future<void> _logAdminAction({
    String? adminId,
    String? adminName,
    required String action,
    String? notificationId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await firestore.collection('admin_actions').add({
        'adminId': adminId,
        'adminName': adminName,
        'action': action,
        'notificationId': notificationId,
        'details': details,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Loglama hatası ana işlemi bozmamalı
    }
  }
}
