import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/components/notification_filter_drawer.dart';
import 'package:kampus_bildirim/components/notification_status_badge.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/models/app_user.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/services/auth_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _searchQuery = '';
  List<NotificationType> _selectedTypes = [];
  bool _onlyOpen = false;
  bool _onlyFollowed = false;
  bool _onlyMyDepartment = false;

  bool _fcmTokenSaved = false;
  Map<String, String> _followedStatusCache =
      {}; // Eski durumları hafızada tutar
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
  }

  /// FCM token'ı Firestore'a kaydet
  Future<void> _ensureFcmTokenSaved(String userId) async {
    if (_fcmTokenSaved) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
        );
        _fcmTokenSaved = true;
        debugPrint('FCM Token kaydedildi (HomePage)');
      }
    } catch (e) {
      debugPrint('FCM Token kaydetme hatası: $e');
    }
  }

  /// Takip edilen bildirimlerin durum değişikliklerini kontrol et
  void _checkForStatusChanges(List<AppNotification> followedNotifications) {
    if (_isFirstLoad) {
      for (final notification in followedNotifications) {
        _followedStatusCache[notification.id] = notification.status.name;
      }
      _isFirstLoad = false;
      return;
    }

    for (final notification in followedNotifications) {
      final cachedStatus = _followedStatusCache[notification.id];
      final currentStatus = notification.status.name;

      if (cachedStatus != null && cachedStatus != currentStatus) {
        _showStatusChangeNotification(
          notification,
          cachedStatus,
          currentStatus,
        );
      }
      _followedStatusCache[notification.id] = currentStatus;
    }
  }

  /// Durum değişikliği bildirimi göster (SnackBar)
  void _showStatusChangeNotification(
    AppNotification notification,
    String oldStatus,
    String newStatus,
  ) {
    final statusLabels = {
      'open': 'Açık',
      'reviewing': 'İnceleniyor',
      'resolved': 'Çözüldü',
    };

    final newStatusLabel = statusLabels[newStatus] ?? newStatus;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '📢 Durum Güncellendi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '"${notification.title}" artık "$newStatusLabel" durumunda.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Görüntüle',
          textColor: Colors.white,
          onPressed: () {
            context.push('/notification-detail/${notification.id}');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final authService = ref.watch(authServiceProvider);

    return userProfileAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Hata: $err'))),
      data: (AppUser? user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _ensureFcmTokenSaved(user.uid);

        final followedNotificationsAsync = ref.watch(
          followedNotificationsProvider(user.uid),
        );

        followedNotificationsAsync.whenData((followedList) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkForStatusChanges(followedList);
          });
        });

        final Set<String> followedIds =
            followedNotificationsAsync.value?.map((e) => e.id).toSet() ?? {};

        return Scaffold(
          endDrawer: NotificationFilterDrawer(
            user: user,
            initialSelectedTypes: _selectedTypes,
            initialOnlyOpen: _onlyOpen,
            initialOnlyFollowed: _onlyFollowed,
            initialOnlyMyDepartment: _onlyMyDepartment,
            onApply: (types, open, followed, department) {
              setState(() {
                _selectedTypes = types;
                _onlyOpen = open;
                _onlyFollowed = followed;
                _onlyMyDepartment = department;
              });
            },
          ),

          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sol alt - Harita butonu
                FloatingActionButton(
                  heroTag: 'mapBtn',
                  onPressed: () => context.push('/map'),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on),
                ),
                // Sağ alt - Duyuru ekleme butonu
                FloatingActionButton(
                  heroTag: 'addBtn',
                  onPressed: () => context.push('/add-notification'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => context.push("/profile"),
                customBorder: const CircleBorder(),
                child: userProfileAsync.when(
                  loading:
                      () => Icon(
                        Icons.account_circle,
                        size: 38,
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                  error:
                      (_, __) => Icon(
                        Icons.account_circle,
                        size: 38,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  data: (user) {
                    if (user != null &&
                        user.avatarUrl != null &&
                        user.avatarUrl!.isNotEmpty) {
                      return CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(user.avatarUrl!),
                        radius: 19,
                      );
                    }
                    return Icon(
                      Icons.account_circle,
                      size: 38,
                      color: Theme.of(context).colorScheme.secondary,
                    );
                  },
                ),
              ),
            ),
            title: SizedBox(
              height: 50,
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Ara...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                  suffixIcon: Builder(
                    builder:
                        (context) => IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          tooltip: "Filtrele",
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade300, // Hafif gri arka plan
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  authService.signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 5),
            ],
          ),

          body: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (err, stack) =>
                    Center(child: Text('Bildirimler yüklenemedi: $err')),
            data: (allNotifications) {
              final filteredList =
                  allNotifications.where((notification) {
                    // Arama Filtresi
                    final searchLower = _searchQuery.toLowerCase();
                    final titleLower = notification.title.toLowerCase();
                    final contentLower = notification.content.toLowerCase();
                    if (!(titleLower.contains(searchLower) ||
                        contentLower.contains(searchLower))) {
                      return false;
                    }

                    // Tür Filtresi
                    if (_selectedTypes.isNotEmpty) {
                      if (!_selectedTypes.contains(notification.type))
                        return false;
                    }

                    // Durum Filtresi (Sadece Açık)
                    if (_onlyOpen) {
                      if (notification.status == NotificationStatus.resolved)
                        return false;
                    }

                    // Takip Filtresi (ID Listesi ile kontrol)
                    if (_onlyFollowed) {
                      if (!followedIds.contains(notification.id)) return false;
                    }

                    // Departman Filtresi
                    if (_onlyMyDepartment) {
                      if (notification.department != user.department)
                        return false;
                    }

                    return true;
                  }).toList();

              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Kriterlere uygun bildirim yok.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final notification = filteredList[index];

                  return Card(
                    color: const Color.fromARGB(255, 242, 241, 241),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                    child: ListTile(
                      leading: Container(
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
                      title: Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${notification.createdAt.day}/${notification.createdAt.month} - ${notification.createdAt.hour}:${notification.createdAt.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      trailing: NotificationStatusBadge(
                        notification: notification,
                      ),
                      onTap: () {
                        context.push('/notification-detail/${notification.id}');
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
