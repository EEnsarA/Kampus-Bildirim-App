import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _fcmTokenSaved = false;

  // Takip edilen bildirimlerin durumlarını cache'le (değişiklik tespiti için)
  Map<String, String> _followedStatusCache = {};
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
  }

  /// FCM token'ı Firestore'a kaydet (takip edilen bildirimlerin durumu değişince bildirim almak için)
  Future<void> _ensureFcmTokenSaved(String userId) async {
    if (_fcmTokenSaved) return; // Zaten kaydedildiyse tekrar kaydetme

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
    // İlk yüklemede sadece cache'i doldur, bildirim gösterme
    if (_isFirstLoad) {
      for (final notification in followedNotifications) {
        _followedStatusCache[notification.id] = notification.status.name;
      }
      _isFirstLoad = false;
      return;
    }

    // Durum değişikliklerini kontrol et
    for (final notification in followedNotifications) {
      final cachedStatus = _followedStatusCache[notification.id];
      final currentStatus = notification.status.name;

      // Eğer cache'de varsa ve durum değiştiyse
      if (cachedStatus != null && cachedStatus != currentStatus) {
        // In-app bildirim göster
        _showStatusChangeNotification(
          notification,
          cachedStatus,
          currentStatus,
        );
      }

      // Cache'i güncelle
      _followedStatusCache[notification.id] = currentStatus;
    }
  }

  /// Durum değişikliği bildirimi göster
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
    //ref (providers)
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

        // Kullanıcı yüklendiğinde FCM token'ı kaydet
        _ensureFcmTokenSaved(user.uid);

        // Takip edilen bildirimleri dinle ve durum değişikliklerini kontrol et
        final followedAsync = ref.watch(
          followedNotificationsProvider(user.uid),
        );
        followedAsync.whenData((followedList) {
          // Sadece build sırasında değil, frame sonunda kontrol et
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkForStatusChanges(followedList);
          });
        });

        return Scaffold(
          endDrawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Filtrele",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  CheckboxListTile(
                    value: false, // Burayı state ile yönetmelisin
                    title: const Text("Sadece Okunmamışlar"),
                    onChanged: (val) {},
                  ),
                  CheckboxListTile(
                    value: false,
                    title: const Text("Yüksek Öncelik"),
                    onChanged: (val) {},
                  ),
                ],
              ),
            ),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.push('/add-notification');
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add),
          ),

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0, // shadow
            titleSpacing: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: Colors.grey.shade200, height: 1.0),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                top: 8,
                bottom: 8,
                right: 8,
              ),
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
                  fillColor: Colors.grey.shade300,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            actions: [
              IconButton(
                icon: Icon(
                  Icons.map_outlined,
                  size: 26,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                tooltip: "Haritada Gör",
                onPressed: () {
                  //  push geri dönmeli
                  context.push('/map');
                },
              ),

              IconButton(
                onPressed: () async {
                  authService.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: Icon(Icons.logout),
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
                    // Hem search bar inputu hem notificationdan gelen title ve content küçük harf yapılır ve bu şekilde filtrelenir
                    final searchLower = _searchQuery.toLowerCase();
                    final titleLower = notification.title.toLowerCase();
                    final contentLower = notification.content.toLowerCase();
                    return titleLower.contains(searchLower) ||
                        contentLower.contains(searchLower);
                  }).toList();

              if (filteredList.isEmpty) {
                return const Center(child: Text("Bildirim bulunamadı."));
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
                    color: Color.fromARGB(255, 242, 241, 241),
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
