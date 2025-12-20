import 'package:cloud_firestore/cloud_firestore.dart';
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
              .toList();
        });
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
  Future<void> updateNotificationStatus({
    required String notificationId,
    required NotificationStatus newStatus,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Bildirim durumu güncellenemedi: $e');
    }
  }

  /// Bildirimin içeriğini güncelle (Admin için)
  Future<void> updateNotificationContent({
    required String notificationId,
    required String content,
  }) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
    } catch (e) {
      throw Exception('Bildirim takibi kaldırılamadı: $e');
    }
  }

  /// Kullanıcının takip ettiği bildirimleri getir
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
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
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
  }) async {
    try {
      final docRef = await _notificationsCollection.add({
        'title': title,
        'content': content,
        'type': NotificationType.emergency.name,
        'status': NotificationStatus.open.name,
        'latitude': 0.0, // Acil bildirimler konum spesifik değil
        'longitude': 0.0,
        'senderId': adminId,
        'senderName': adminName,
        'department': 'YÖNETİM',
        'imageUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'followedBy': [],
        'isEmergency': true, // Flag olarak işaretle
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Acil bildirim yayınlanamadı: $e');
    }
  }
}
