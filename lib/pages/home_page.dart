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

        final followedNotificationsAsync = ref.watch(
          followedNotificationsProvider(user.uid),
        );

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
                    // filtreler
                    final searchLower = _searchQuery.toLowerCase();
                    final titleLower = notification.title.toLowerCase();
                    final contentLower = notification.content.toLowerCase();
                    final matchesSearch =
                        titleLower.contains(searchLower) ||
                        contentLower.contains(searchLower);
                    if (!matchesSearch) return false;

                    // Tür Filtresi
                    if (_selectedTypes.isNotEmpty) {
                      if (!_selectedTypes.contains(notification.type)) {
                        return false;
                      }
                    }

                    // Durum Filtresi (Sadece Açık Olanlar)
                    if (_onlyOpen) {
                      if (notification.status == NotificationStatus.resolved) {
                        return false;
                      }
                    }

                    if (_onlyFollowed) {
                      if (!followedIds.contains(notification.id)) {
                        return false;
                      }
                    }

                    // Departman Filtresi (Admin için)
                    if (_onlyMyDepartment) {
                      if (notification.department != user.department) {
                        return false;
                      }
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
