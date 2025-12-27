/// =============================================================================
/// KAMPÜS BİLDİRİM - Bildirim Provider'ları (notification_provider.dart)
/// =============================================================================
/// Bu dosya Riverpod state yönetimi için bildirim provider'larını içerir.
/// Repository katçatısı ile UI arasında köprü görevi görür.
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';

// =============================================================================
// ANA BİLDİRİM PROVIDER'I
// =============================================================================
/// Tüm bildirimleri gerçek zamanlı olarak dinler.
/// StreamProvider: Firestore'dan gelen değişiklikleri otomatik yansıtır.
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getAllNotificationsStream();
});

// =============================================================================
// DETAY PROVIDER'I
// =============================================================================
/// Belirli bir bildirimi ID ile getirir.
/// FutureProvider.family: Parametreli async veri çekme için kullanılır.
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
