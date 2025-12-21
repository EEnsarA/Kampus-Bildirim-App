import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/components/custom_toast.dart';
import 'package:kampus_bildirim/components/status_tag.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/models/app_user.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kampus_bildirim/constants/app_colors.dart';
import 'admin_actions_page.dart';

/// Admin paneli sayfası
/// Sadece admin rol'ü olan kullanıcılar erişebilir
/// Tüm bildirimleri yönetir: durumu günceller, acil duyuru yayınlar
class AdminPanelPage extends ConsumerStatefulWidget {
  const AdminPanelPage({super.key});

  @override
  ConsumerState<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends ConsumerState<AdminPanelPage> {
  // Acil bildirim gönderme formundaki kontroller
  final TextEditingController _emergencyTitleController =
      TextEditingController();
  final TextEditingController _emergencyContentController =
      TextEditingController();

  @override
  void dispose() {
    _emergencyTitleController.dispose();
    _emergencyContentController.dispose();
    super.dispose();
  }

  /// Basit kullanıcı yönetim arayüzü: kullanıcıları listeler ve role değiştirir
  Widget _buildUserManagementSection(AppUser currentAdmin) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kullanıcı Yönetimi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('name')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Kullanıcı bulunamadı.'),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;
                    final user = AppUser.fromMap(data, uid);

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.fullName),
                      subtitle: Text(user.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.role.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          if (user.uid != currentAdmin.uid)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'make_admin') {
                                  _changeUserRole(ref, uid, 'admin');
                                } else if (value == 'make_user') {
                                  _changeUserRole(ref, uid, 'user');
                                }
                              },
                              itemBuilder:
                                  (ctx) => [
                                    if (user.role != 'admin')
                                      const PopupMenuItem(
                                        value: 'make_admin',
                                        child: Text('Yönetici yap'),
                                      ),
                                    if (user.role == 'admin')
                                      const PopupMenuItem(
                                        value: 'make_user',
                                        child: Text('Yöneticiliği kaldır'),
                                      ),
                                  ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Kullanıcı rolünü güncelle (basit update)
  Future<void> _changeUserRole(
    WidgetRef ref,
    String uid,
    String newRole,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'role': newRole,
      });
      if (!mounted) return;
      showCustomToast(this.context, 'Kullanıcı rolü güncellendi');
    } catch (e) {
      if (!mounted) return;
      showCustomToast(this.context, 'Hata: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giriş yapan kullanıcı bilgilerini al (admin kontrolü için)
    final userAsync = ref.watch(userProfileProvider);
    // Tüm bildirimleri listele
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Admin Paneli',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) =>
                Center(child: Text('Kullanıcı bilgisi yüklenemedi: $err')),
        data: (user) {
          // Admin değilse erişim reddedilir
          if (user == null || user.role != 'admin') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu sayfaya yalnızca admin erişebilir.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Ana Sayfaya Dön'),
                  ),
                ],
              ),
            );
          }

          // Admin ise paneli göster: Acil duyuru üstte sabit, alt kısımda iki sekme
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Acil Bildirim Gönderme Modülü (her zaman görünür)
                _buildEmergencyNotificationSection(user),

                const SizedBox(height: 24),

                // Sekmeli yönetim: Bildirimler / Kullanıcılar
                DefaultTabController(
                  length: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AdminActionsPage(),
                                ),
                              ),
                          icon: Icon(
                            Icons.history,
                            color: AppColors.primaryColor,
                          ),
                          label: Text(
                            'İşlem Kayıtları',
                            style: TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ),
                      TabBar(
                        labelColor: AppColors.primaryColor,
                        unselectedLabelColor: Colors.grey.shade600,
                        indicatorColor: AppColors.primaryColor,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        tabs: const [
                          Tab(text: 'Bildirim Yönetimi'),
                          Tab(text: 'Kullanıcı Yönetimi'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        // Yeterli yüksekliği vererek içeriğin kaydırılmasını sağla
                        height: 600,
                        child: TabBarView(
                          children: [
                            // Bildirim yönetimi sekmesi
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: notificationsAsync.when(
                                loading:
                                    () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                error:
                                    (err, stack) => Center(
                                      child: Text(
                                        'Bildirimler yüklenemedi: $err',
                                      ),
                                    ),
                                data: (notifications) {
                                  if (notifications.isEmpty) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.inbox,
                                                size: 48,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 12),
                                              const Text('Henüz bildirim yok'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      return _buildNotificationAdminCard(
                                        context,
                                        ref,
                                        notification,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            // Kullanıcı yönetimi sekmesi
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _buildUserManagementSection(user),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Acil bildirim gönderme formunu oluşturur
  Widget _buildEmergencyNotificationSection(AppUser user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Acil Durum Bildirimi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Başlık İnput'u
            TextField(
              controller: _emergencyTitleController,
              decoration: InputDecoration(
                hintText: 'Acil duyuru başlığı (ör: Kampüste İtfaiye)',
                labelText: 'Başlık',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 12),

            // İçerik İnput'u
            TextField(
              controller: _emergencyContentController,
              decoration: InputDecoration(
                hintText: 'Acil duyuru içeriği...',
                labelText: 'İçerik',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            // Gönder Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sendEmergencyNotification(ref, user),
                icon: const Icon(Icons.send),
                label: const Text('Acil Duyuru Yayınla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Her bildirim için admin kontrol kartını oluşturur
  /// Durum güncelleme butonlarını ve detay bağlantısını içerir
  Widget _buildNotificationAdminCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bildirim başlık ve bilgileri
            Row(
              children: [
                // Tür ikonu
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.typeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification.typeIcon,
                    color: notification.typeColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Başlık ve açıklama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        notification.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Mevcut durum etiketi
                StatusTag(
                  text: notification.statusLabel,
                  color: notification.statusColor,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Durum güncelleme butonları (3 aşama)
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

            // Detay sayfasına git butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    () =>
                        context.push('/notification-detail/${notification.id}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: BorderSide(
                    color: AppColors.primaryColor.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Detaylarını Gör'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Admin'in durumu değiştirmek için kullandığı mini buton
  /// Mevcut duruma göre renk değişir
  Widget _buildStatusButton(
    WidgetRef ref,
    AppNotification notification,
    NotificationStatus status,
    String label,
  ) {
    // Bu butonun geçerli duruma ait olup olmadığını kontrol et
    final isCurrentStatus = notification.status == status;

    return ElevatedButton(
      onPressed:
          isCurrentStatus
              ? null
              : () => _updateStatusQuick(ref, notification, status),
      style: ElevatedButton.styleFrom(
        // Mevcut durum yeşil, diğerleri gri
        backgroundColor: isCurrentStatus ? Colors.green : Colors.grey.shade300,
        foregroundColor: isCurrentStatus ? Colors.white : Colors.black,
        disabledBackgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  /// Hızlı durum güncelleme (admin panelinden)
  Future<void> _updateStatusQuick(
    WidgetRef ref,
    AppNotification notification,
    NotificationStatus newStatus,
  ) async {
    try {
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
      if (!mounted) return;
      showCustomToast(
        this.context,
        '${notification.title} bildirimi "${newStatus.name}" durumuna güncellendi.',
      );
    } catch (e) {
      if (!mounted) return;
      showCustomToast(this.context, 'Hata: $e', isError: true);
    }
  }

  /// Acil duyuru yayınla
  /// Tüm kullanıcılara gidecek önemli bildirim
  Future<void> _sendEmergencyNotification(WidgetRef ref, AppUser admin) async {
    // Form doğrulaması
    if (_emergencyTitleController.text.isEmpty ||
        _emergencyContentController.text.isEmpty) {
      showCustomToast(
        this.context,
        'Başlık ve içeriği doldurunuz.',
        isError: true,
      );
      return;
    }

    try {
      // Repository aracılığıyla acil duyuru oluştur
      final repository = ref.read(notificationRepositoryProvider);
      await repository.createEmergencyNotification(
        title: _emergencyTitleController.text.trim(),
        content: _emergencyContentController.text.trim(),
        adminId: admin.uid,
        adminName: admin.fullName,
      );
      if (!mounted) return;
      // Form temizle
      _emergencyTitleController.clear();
      _emergencyContentController.clear();

      // Başarı mesajı göster
      showCustomToast(
        this.context,
        'Acil duyuru tüm kullanıcılara yayınlandı!',
      );

      // Listeyi yenile
      ref.watch(notificationsProvider);
    } catch (e) {
      if (!mounted) return;
      showCustomToast(context, 'Hata: $e', isError: true);
    }
  }
}
