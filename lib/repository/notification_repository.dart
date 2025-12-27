import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

// Provider'ı bir kez oluştur ve merkezi olarak kullan
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(firestore: FirebaseFirestore.instance);
});

class NotificationRepository {
  final FirebaseFirestore firestore;

  NotificationRepository({required this.firestore});

  // Collection reference
  CollectionReference get _notificationsCollection =>
      firestore.collection('notifications');

  /// Tüm bildirimleri güncellemeden eski'ye doğru sıralanmış şekilde stream olarak getir
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
              .where((n) => n.isDeleted == false)
              .toList();
        });
  }

  /// Soft-delete a notification (mark as deleted)
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

  /// Restore a soft-deleted notification
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

  /// Belirli bir bildirimi ID ile getir
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

  /// Yeni bildirim oluştur
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
        'status': NotificationStatus.open.name,
        'latitude': latitude,
        'longitude': longitude,
        'senderId': senderId,
        'senderName': senderName,
        'department': department,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'followedBy': [], // Takip edenler listesi
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Bildirim oluşturulamadı: $e');
    }
  }

  /// Bildirimin durumunu güncelle (Admin için)
  /// Takipçilere FCM bildirimi gönderilmesi için status_updates collection'ına yazar
  Future<void> updateNotificationStatus({
    required String notificationId,
    required NotificationStatus newStatus,
    String? adminId,
    String? adminName,
  }) async {
    try {
      // Önce mevcut bildirimi al (eski durumu ve takipçileri almak için)
      final doc = await _notificationsCollection.doc(notificationId).get();
      if (!doc.exists) {
        throw Exception('Bildirim bulunamadı');
      }

      final data = doc.data() as Map<String, dynamic>;
      final oldStatus = data['status'] ?? 'open';
      final followers = List<String>.from(data['followedBy'] ?? []);
      final notificationTitle = data['title'] ?? 'Bildirim';

      // Durumu güncelle
      await _notificationsCollection.doc(notificationId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log admin action
      if (adminId != null || adminName != null) {
        await _logAdminAction(
          adminId: adminId,
          adminName: adminName,
          action: 'update_status',
          notificationId: notificationId,
          details: {'oldStatus': oldStatus, 'newStatus': newStatus.name},
        );
      }

      // Takipçilere bildirim göndermek için fcm_messages collection'ına yaz
      // Bu collection zaten çalışan sendEmergencyNotification Cloud Function tarafından dinleniyor
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

  /// Bildirimin içeriğini güncelle (Admin için)
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
      // Log admin action
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

  /// Bildirimi takip et
  Future<void> followNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'followedBy': FieldValue.arrayUnion([userId]),
      });
      // Log the user action for audit (follow)
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

  /// Bildiriyi takipten çıkar
  Future<void> unfollowNotification({
    required String notificationId,
    required String userId,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'followedBy': FieldValue.arrayRemove([userId]),
      });
      // Log the user action for audit (unfollow)
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

  /// Kullanıcının takip ettiği bildirimleri getir
  /// NOT: Bu sorgu Firestore'da composite index gerektirir:
  /// Collection: notifications
  /// Fields: followedBy (Arrays) + createdAt (Descending)
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

  /// Tür bazlı bildirimleri filtrelemek için
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

  /// Durum bazlı bildirimleri filtrelemek için (açık bildirimler gibi)
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

  /// Başlık ve içerikle ara
  Future<List<AppNotification>> searchNotifications(String query) async {
    try {
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

      // Firestore full-text search desteklemediği için client-side arama yapıyoruz
      return allNotifications.where((notification) {
        final queryLower = query.toLowerCase();
        return notification.title.toLowerCase().contains(queryLower) ||
            notification.content.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      throw Exception('Arama yapılamadı: $e');
    }
  }

  /// Bildirimi sil (Admin için - opsiyonel)
  Future<void> deleteNotification(
    String notificationId, {
    String? adminId,
    String? adminName,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      // Log deletion with optional admin info
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

  /// Acil bildirim yayınla (Admin için)
  Future<String> createEmergencyNotification({
    required String title,
    required String content,
    required String adminId,
    required String adminName,
    double latitude = 39.9042, // Varsayılan: kampüs merkezi
    double longitude = 32.8642,
  }) async {
    try {
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
        'isEmergency': true, // Flag olarak işaretle
      });
      // Log emergency publish
      await _logAdminAction(
        adminId: adminId,
        adminName: adminName,
        action: 'create_emergency',
        notificationId: docRef.id,
        details: {'title': title},
      );

      // Also write a marker for Cloud Functions to pick up and send FCM
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

  /// İç denetim (audit) kaydı ekler
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
      // Logging failure should not break main flow
    }
  }
}
