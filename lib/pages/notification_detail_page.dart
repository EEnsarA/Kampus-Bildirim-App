/// =============================================================================
/// KAMPÜS BİLDİRİM - Bildirim Detay Sayfası (notification_detail_page.dart)
/// =============================================================================
/// Bu dosya seçilen bildirimin detaylarını gösterir.
///
/// İçerdiği Özellikler:
/// - Bildirim başlık, içerik, resim, konum gösterimi
/// - Gönderici bilgisi kartı
/// - Takip etme/bırakma işlevi
/// - Admin: Durum güncelleme, içerik düzenleme, silme
/// - Harita önizlemesi (mini map)
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Mini harita

// Bileşenler
import 'package:kampus_bildirim/components/notification_status_badge.dart';
import 'package:kampus_bildirim/components/sender_info_card.dart';
import 'package:kampus_bildirim/components/custom_toast.dart';

// Modeller ve Provider'lar
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';

// =============================================================================
// NotificationDetailPage Widget'ı
// =============================================================================
/// Bildirim detaylarını gösteren sayfa.
/// ID ile Firestore'dan taze veri çeker.
class NotificationDetailPage extends ConsumerStatefulWidget {
  /// Gösterilecek bildirimin ID'si
  final String notificationId;

  const NotificationDetailPage({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailPage> createState() =>
      _NotificationDetailPageState();
}

class _NotificationDetailPageState
    extends ConsumerState<NotificationDetailPage> {
  /// Kullanıcı bu bildirimi takip ediyor mu?
  bool _isFollowing = false;

  // -------------------------------------------------------------------------
  // Takip Etme/Bırakma
  // -------------------------------------------------------------------------
  /// Bildirimi takibe alır veya takipten çıkarır.
  Future<void> _toggleFollowNotification(
    WidgetRef ref,
    AppNotification notification,
    String userId,
  ) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);

      if (_isFollowing) {
        await repository.unfollowNotification(
          notificationId: notification.id,
          userId: userId,
        );
        setState(() => _isFollowing = false);
        if (!mounted) return;
        showCustomToast(context, 'Bildirimin takibi sonlandırıldı');
      } else {
        await repository.followNotification(
          notificationId: notification.id,
          userId: userId,
        );
        setState(() => _isFollowing = true);
        if (!mounted) return;
        showCustomToast(context, 'Bildirim takibe alındı ❤️');
      }

      // Listeyi yenile
      ref.invalidate(notificationsProvider);
      // Detayı yenile
      ref.invalidate(notificationDetailProvider(notification.id));
    } catch (e) {
      if (!mounted) return;
      showCustomToast(context, 'Hata: $e', isError: true);
    }
  }

  /// Tarih formatlayıcı
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Admin durum güncelleme butonu
  Widget _buildStatusButton(
    WidgetRef ref,
    AppNotification notification,
    NotificationStatus status,
    String label,
  ) {
    final isCurrentStatus = notification.status == status;

    return ElevatedButton(
      onPressed:
          isCurrentStatus
              ? null
              : () => _updateNotificationStatus(ref, notification, status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? Colors.green : Colors.grey.shade300,
        foregroundColor: isCurrentStatus ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  /// Admin durum güncelleme fonksiyonu
  Future<void> _updateNotificationStatus(
    WidgetRef ref,
    AppNotification notification,
    NotificationStatus newStatus,
  ) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final admin = ref.read(userProfileProvider).value;

      await repository.updateNotificationStatus(
        notificationId: notification.id,
        newStatus: newStatus,
        adminId: admin?.uid,
        adminName: admin?.fullName,
      );

      if (!mounted) return;
      showCustomToast(context, 'Bildirim durumu güncellendi.');
      ref.invalidate(notificationDetailProvider(notification.id));
    } catch (e) {
      if (!mounted) return;
      showCustomToast(context, 'Hata: $e', isError: true);
    }
  }

  /// Admin açıklama düzenleme
  Future<void> _showEditContentDialog(
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: notification.content,
    );

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Açıklamayı Düzenle'),
            content: TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );

    if (result == true) {
      final newContent = controller.text.trim();
      if (newContent.isEmpty) return;

      try {
        final repository = ref.read(notificationRepositoryProvider);
        final admin = ref.read(userProfileProvider).value;

        await repository.updateNotificationContent(
          notificationId: notification.id,
          content: newContent,
          adminId: admin?.uid,
          adminName: admin?.fullName,
        );

        if (!mounted) return;
        showCustomToast(context, 'Açıklama güncellendi');
        ref.invalidate(notificationDetailProvider(notification.id));
      } catch (e) {
        if (!mounted) return;
        showCustomToast(context, 'Hata: $e', isError: true);
      }
    }
  }

  /// Admin soft-delete fonksiyonu
  Future<void> _confirmAndDeleteNotification(
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Bildirimi Sonlandır'),
            content: const Text(
              'Bu bildirimi sonlandırmak istediğinize emin misiniz? Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Hayır'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Evet'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(notificationRepositoryProvider);
        final admin = ref.read(userProfileProvider).value;

        await repository.softDeleteNotification(
          notification.id,
          adminId: admin?.uid,
          adminName: admin?.fullName,
        );

        if (!mounted) return;
        showCustomToast(context, 'Bildirim sonlandırıldı.');
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        showCustomToast(context, 'Hata: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ID ile veriyi çekiyoruz (Arkadaşının yöntemi)
    final notificationAsync = ref.watch(
      notificationDetailProvider(widget.notificationId),
    );
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bildirim Detayı",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      // Veri yüklenirken veya hata varsa gösterilecekler
      body: notificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (notification) {
          if (notification == null) {
            return const Center(child: Text("Bildirim bulunamadı."));
          }

          // Admin kontrolü
          bool isAdmin = false;
          final user = userAsync.value;
          if (user != null && user.role == "admin") {
            isAdmin = true;
          }

          // Takip durumunu başlat (Sayfa ilk açıldığında kontrol edilebilir, şimdilik false başlıyor butona basınca değişiyor)
          // Eğer backend'de "followers" listesi varsa burada _isFollowing = notification.followers.contains(user.uid) gibi bir set işlemi yapılabilir.
          // Basitlik adına şimdilik manuel bırakıyorum.

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- GÖRSEL ALANI (Senin tasarımın) ---
                          if (notification.imageUrl != null)
                            Container(
                              width: double.infinity,
                              height: 200,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(notification.imageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: notification.typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Icon(
                                  notification.typeIcon,
                                  size: 50,
                                  color: notification.typeColor,
                                ),
                              ),
                            ),

                          // --- BAŞLIK ve TARİH (Senin tasarımın) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              NotificationStatusBadge(
                                notification: notification,
                              ),
                              Text(
                                _formatDate(notification.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                notification.typeIcon,
                                color: notification.typeColor,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                notification.typeLabel.toUpperCase(),
                                style: TextStyle(
                                  color: notification.typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),
                          const Divider(),
                          const SizedBox(height: 5),

                          // --- İÇERİK ---
                          Text(
                            notification.content,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),

                          const SizedBox(height: 20),

                          // --- HARİTA (Arkadaşının kodu ama senin tasarımın içinde) ---
                          const Text(
                            'Konum',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 200,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    notification.latitude,
                                    notification.longitude,
                                  ),
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('notification'),
                                    position: LatLng(
                                      notification.latitude,
                                      notification.longitude,
                                    ),
                                    infoWindow: InfoWindow(
                                      title: notification.title,
                                    ),
                                  ),
                                },
                                zoomGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                                myLocationButtonEnabled: false,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // --- YENİ: TAKİP ET BUTONU (Buraya entegre ettik) ---
                          if (user != null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _toggleFollowNotification(
                                      ref,
                                      notification,
                                      user.uid,
                                    ),
                                icon: Icon(
                                  _isFollowing
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                label: Text(
                                  _isFollowing ? 'Takipten Çık' : 'Takip Et',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isFollowing
                                          ? Colors.red.shade100
                                          : Colors.blue.shade50,
                                  foregroundColor:
                                      _isFollowing ? Colors.red : Colors.blue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // --- ADMIN PANELİ ---
                          if (isAdmin) ...[
                            const Divider(thickness: 1.5),
                            const SizedBox(height: 10),
                            const Text(
                              'Yönetici Paneli',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Durum Butonları
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatusButton(
                                    ref,
                                    notification,
                                    NotificationStatus.open,
                                    'Açık',
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: _buildStatusButton(
                                    ref,
                                    notification,
                                    NotificationStatus.reviewing,
                                    'İnceleniyor',
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: _buildStatusButton(
                                    ref,
                                    notification,
                                    NotificationStatus.resolved,
                                    'Çözüldü',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Düzenle ve Sil
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        () => _showEditContentDialog(
                                          ref,
                                          notification,
                                        ),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Düzenle'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed:
                                        () => _confirmAndDeleteNotification(
                                          ref,
                                          notification,
                                        ),
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Sonlandır',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          const Spacer(),
                          const SizedBox(height: 20),

                          // --- SENİN SENDER CARD TASARIMIN ---
                          SenderInfoCard(senderId: notification.senderId),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // --- SENİN FAB BUTONUN ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Burada notification verisine erişmek için veriyi tekrar okuyabiliriz
          // veya notificationAsync.value üzerinden alabiliriz ama null check lazım.
          final notification = notificationAsync.value;
          if (notification != null) {
            context.push('/map', extra: notification);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.location_on, color: Colors.white),
        label: const Text(
          "Konumda Gör",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
