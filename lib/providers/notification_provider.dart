import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';

// Tüm bildirimleri merkezi repository üzerinden getir
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getAllNotificationsStream();
});

// Belirli bir bildirimi ID ile getir
final notificationDetailProvider =
    FutureProvider.family<AppNotification?, String>((
      ref,
      notificationId,
    ) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationById(notificationId);
    });

// Kullanıcının takip ettiği bildirimleri getir
// NOT: autoDispose kaldırıldı - sayfa geçişlerinde sürekli yeniden oluşturulması döngüye neden oluyordu
final followedNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
      final repository = ref.read(notificationRepositoryProvider);
      return repository.getFollowedNotificationsStream(userId);
    });

// Tür bazlı bildirimleri getir
final notificationsByTypeProvider =
    StreamProvider.family<List<AppNotification>, NotificationType>((ref, type) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByType(type);
    });

// Durum bazlı bildirimleri getir (açık bildirimler gibi)
final notificationsByStatusProvider =
    StreamProvider.family<List<AppNotification>, NotificationStatus>((
      ref,
      status,
    ) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByStatus(status);
    });

// Arama yapmak için
final searchNotificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, query) async {
      final repository = ref.watch(notificationRepositoryProvider);
      if (query.isEmpty) {
        return [];
      }
      return repository.searchNotifications(query);
    });
