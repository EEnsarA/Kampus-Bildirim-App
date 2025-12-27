// notification_provider.dart
// Riverpod ile bildirim state yönetimi
// StreamProvider kullanıldı çünkü firestore realtime dinleme yapıyor

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';

// tüm bildirimleri dinle
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getAllNotificationsStream();
});

// tek bildirim detayı
final notificationDetailProvider =
    FutureProvider.family<AppNotification?, String>((
      ref,
      notificationId,
    ) async {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationById(notificationId);
    });

// =============================================================================
// TAKİP EDİLEN BİLDİRİMLER PROVIDER'I
// =============================================================================
/// Kullanıcının takip ettiği bildirimleri gerçek zamanlı dinler.
/// userId parametresi ile kullanıcıya özel filtreleme yapar.
final followedNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getFollowedNotificationsStream(userId);
    });

// =============================================================================
// TÜR BAZLI FİLTRELEME PROVIDER'I
// =============================================================================
/// Belirli bir türdeki bildirimleri filtreler.
/// Örn: Sadece acil durumları veya etkinlikleri listelemek için.
final notificationsByTypeProvider =
    StreamProvider.family<List<AppNotification>, NotificationType>((ref, type) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByType(type);
    });

// =============================================================================
// DURUM BAZLI FİLTRELEME PROVIDER'I
// =============================================================================
/// Belirli bir durumdaki bildirimleri filtreler.
/// Örn: Sadece açık veya çözülmüş bildirimleri listelemek için.
final notificationsByStatusProvider =
    StreamProvider.family<List<AppNotification>, NotificationStatus>((
      ref,
      status,
    ) {
      final repository = ref.watch(notificationRepositoryProvider);
      return repository.getNotificationsByStatus(status);
    });

// =============================================================================
// ARAMA PROVIDER'I
// =============================================================================
/// Verilen sorguya göre bildirimlerde arama yapar.
/// Client-side arama: Firestore full-text search desteklemediği için.
final searchNotificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((ref, query) async {
      final repository = ref.watch(notificationRepositoryProvider);
      if (query.isEmpty) {
        return [];
      }
      return repository.searchNotifications(query);
    });
