import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kampus_bildirim/components/custom_toast.dart';
import 'package:kampus_bildirim/components/status_tag.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';

/// Bildirimin tüm detaylarını gösteren sayfa
/// Kullanıcılar bildirimleri takip edebilir, admin'ler durumu güncelleyebilir
class NotificationDetailPage extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailPage({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailPage> createState() =>
      _NotificationDetailPageState();
}

class _NotificationDetailPageState
    extends ConsumerState<NotificationDetailPage> {
  // Kullanıcının bu bildirimi takip edip etmediğini belirten flag
  bool _isFollowing = false;

  @override
  Widget build(BuildContext context) {
    // Bildirimi ID'ye göre yükle
    final notificationAsync = ref.watch(
      notificationDetailProvider(widget.notificationId),
    );
    // Giriş yapan kullanıcı bilgilerini al (admin kontrolü için)
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim Detayları'), elevation: 1),
      body: notificationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox.shrink(),
                  Text('Bildirim yüklenemedi: $err'),
                ],
              ),
            ),
        data: (notification) {
          if (notification == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.not_interested,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('Bildirim bulunamadı'),
                ],
              ),
            );
          }

          return userAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Hata: $err')),
            data: (user) {
              final isAdmin = user?.role == 'admin';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve Tür Kartı
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: notification.typeColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    notification.typeIcon,
                                    color: notification.typeColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          StatusTag(
                                            text: notification.typeLabel,
                                            color: notification.typeColor,
                                          ),
                                          const SizedBox(width: 8),
                                          StatusTag(
                                            text: notification.statusLabel,
                                            color: notification.statusColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bilgi Kartı
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Bildiren Kişi Bilgisi
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tarafından Bildirildi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        notification.senderName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        notification.department,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Tarih
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Oluşturulma Tarihi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(notification.createdAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Açıklama
                    const Text(
                      'Açıklama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          notification.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Resim (varsa)
                    if (notification.imageUrl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resim',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              notification.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Harita
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
                        height: 250,
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
                              infoWindow: InfoWindow(title: notification.title),
                            ),
                          },
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Admin Kontrolleri (sadece admin görsün)
                    if (isAdmin)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'Admin İşlemleri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Durum Güncelleme Butonları
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatusButton(
                                  ref,
                                  notification,
                                  NotificationStatus.reviewing,
                                  'İnceleniyor',
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 12),
                          // Düzenle ve Sonlandır butonları (admin veri UI'sine bağlı)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => _showEditContentDialog(
                                        ref,
                                        notification,
                                      ),
                                  child: const Text('Açıklamayı Düzenle'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                  ),
                                  onPressed:
                                      () => _confirmAndDeleteNotification(
                                        ref,
                                        notification,
                                      ),
                                  child: const Text('Bildirimi Sonlandır'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    // Takip Et / Çık Butonu
                    if (user != null)
                      ElevatedButton.icon(
                        onPressed:
                            () => _toggleFollowNotification(
                              ref,
                              notification,
                              user.uid,
                            ),
                        icon: Icon(
                          _isFollowing ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text(_isFollowing ? 'Takipten Çık' : 'Takip Et'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isFollowing
                                  ? Colors.red.shade400
                                  : Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Admin'in bildirimin durumunu değiştirmek için kullandığı buton
  /// Mevcut duruma göre yeşil gösterilir, diğerleri gri olur
  Widget _buildStatusButton(
    WidgetRef ref,
    AppNotification notification,
    NotificationStatus status,
    String label,
  ) {
    // Bu butonun geçerli duruma ait olup olmadığını kontrol et
    final isCurrentStatus = notification.status == status;

    return ElevatedButton(
      // Zaten bu durumdaysa buton devre dışı olur
      onPressed:
          isCurrentStatus
              ? null
              : () => _updateNotificationStatus(ref, notification, status),
      style: ElevatedButton.styleFrom(
        // Mevcut durum yeşil, diğerleri gri
        backgroundColor: isCurrentStatus ? Colors.green : Colors.grey.shade300,
        foregroundColor: isCurrentStatus ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  /// Admin tarafından bildirimin durumunu güncellemek için kullanılan fonksiyon
  /// Yeni durum Firestore'a kaydedilir ve kullanıcılara bildirim gönderilir
  Future<void> _updateNotificationStatus(
    WidgetRef ref,
    AppNotification notification,
    NotificationStatus newStatus,
  ) async {
    try {
      // Repository aracılığıyla Firestore'u güncelle
      final repository = ref.read(notificationRepositoryProvider);
      final admin = ref
          .read(userProfileProvider)
          .maybeWhen(data: (u) => u, orElse: () => null);
      await repository.updateNotificationStatus(
        notificationId: notification.id,
        newStatus: newStatus,
        adminId: admin?.uid,
        adminName: admin?.fullName,
      );

      // Başarılı olduysa kullanıcıya bildir
      if (!mounted) return;
      showCustomToast(this.context, 'Bildirim durumu güncelleştirme başarılı.');
    } catch (e) {
      // Hata oluşursa toast ile uyar
      if (!mounted) return;
      showCustomToast(this.context, 'Hata: $e', isError: true);
    }
  }

  /// Kullanıcının bildirimi takip etme/çıkma işlemini yönetir
  /// Takip ediyor ise kaldırır, etmiyorsa ekler
  Future<void> _toggleFollowNotification(
    WidgetRef ref,
    AppNotification notification,
    String userId,
  ) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);

      if (_isFollowing) {
        // Zaten takip ediyorsa, takipten çık
        await repository.unfollowNotification(
          notificationId: notification.id,
          userId: userId,
        );
        setState(() => _isFollowing = false);
        if (!mounted) return;
        showCustomToast(this.context, 'Bildirimin takibi sonlandırıldı');
      } else {
        // Takip etmiyorsa, takibe al
        await repository.followNotification(
          notificationId: notification.id,
          userId: userId,
        );
        setState(() => _isFollowing = true);
        if (!mounted) return;
        showCustomToast(this.context, 'Bildirim takibe alındı ❤️');
      }

      // Listeyi otomatik yenile (Riverpod stream güncellemesini tetikle)
      if (!mounted) return;
      ref.watch(notificationsProvider);
    } catch (e) {
      if (!mounted) return;
      showCustomToast(this.context, 'Hata: $e', isError: true);
    }
  }

  /// Admin için açıklamayı düzenleme diyaloğu
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
      if (newContent.isEmpty) {
        if (!mounted) return;
        showCustomToast(this.context, 'Açıklama boş olamaz', isError: true);
        return;
      }

      try {
        final repository = ref.read(notificationRepositoryProvider);
        final admin = ref
            .read(userProfileProvider)
            .maybeWhen(data: (u) => u, orElse: () => null);
        await repository.updateNotificationContent(
          notificationId: notification.id,
          content: newContent,
          adminId: admin?.uid,
          adminName: admin?.fullName,
        );
        if (!mounted) return;
        showCustomToast(this.context, 'Açıklama güncellendi');
        // Yeniden yükle
        ref.invalidate(notificationDetailProvider(notification.id));
      } catch (e) {
        if (!mounted) return;
        showCustomToast(this.context, 'Hata: $e', isError: true);
      }
    }
  }

  /// Admin tarafından bildirimi sonlandırma (silme) onayı
  Future<void> _confirmAndDeleteNotification(
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: this.context,
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
        final admin = ref
            .read(userProfileProvider)
            .maybeWhen(data: (u) => u, orElse: () => null);
        await repository.softDeleteNotification(
          notification.id,
          adminId: admin?.uid,
          adminName: admin?.fullName,
        );
        if (!mounted) return;
        showCustomToast(this.context, 'Bildirim sonlandırıldı (soft-delete)');
        Navigator.of(this.context).pop();
      } catch (e) {
        if (!mounted) return;
        showCustomToast(this.context, 'Hata: $e', isError: true);
      }
    }
  }

  /// Tarihi insan tarafından okunabilir formatta gösterir
  /// Örn: "5 dakika önce", "2 saat önce", "15/12/2025 14:30"
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Son 1 saat içindeyse dakika cinsinden göster
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    }
    // Son 1 gün içindeyse saat cinsinden göster
    else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    }
    // Son 1 hafta içindeyse gün cinsinden göster
    else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    }
    // Aksi halde tam tarih ve saat göster
    else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}
