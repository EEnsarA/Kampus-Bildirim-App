import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/models/app_user.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/services/auth_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //ref (providers)
    final userProfileAsync = ref.watch(userProfileProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final authService = ref.watch(authServiceProvider);
    // Search bar inputu tutan state .
    final searchQuery = ref.watch(searchFilterProvider);

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
            elevation: 1, // shadow
            titleSpacing: 0,

            leading: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.account_circle,
                size: 32,
                color: Theme.of(context).colorScheme.secondary,
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
                  filled: true,
                  fillColor: Colors.grey.shade300, // Hafif gri arka plan
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  ref.read(searchFilterProvider.notifier).state = value;
                },
              ),
            ),

            actions: [
              Builder(
                builder:
                    (context) => IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      tooltip: "Filtrele",
                      onPressed: () => Scaffold.of(context).openEndDrawer(),
                    ),
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
                    final searchLower = searchQuery.toLowerCase();
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

                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: notification.statusColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: notification.statusColor.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          notification.statusLabel,
                          style: TextStyle(
                            color: notification.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      onTap: () {},
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
