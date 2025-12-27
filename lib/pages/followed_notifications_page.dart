// followed_notifications_page.dart
// kullanıcının takip ettiği bildirimler
// NOT: userId cache'ledim yoksa loading döngüsü oluyo

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';

class FollowedNotificationsPage extends ConsumerStatefulWidget {
  const FollowedNotificationsPage({super.key});

  @override
  ConsumerState<FollowedNotificationsPage> createState() =>
      _FollowedNotificationsPageState();
}

class _FollowedNotificationsPageState
    extends ConsumerState<FollowedNotificationsPage> {
  String? _cachedUserId;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    // Kullanıcı yüklendikten sonra userId'yi cache'le
    // Bu sayede sonraki rebuild'lerde loading döngüsüne girilmez
    if (userAsync.hasValue && userAsync.value != null) {
      _cachedUserId = userAsync.value!.uid;
    }

    // Eğer cached userId varsa ve userAsync hala loading ise, cached değeri kullan
    if (_cachedUserId != null) {
      return _buildContent(context, _cachedUserId!);
    }

    return userAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Hata: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Kullanıcı bulunamadı')),
          );
        }
        _cachedUserId = user.uid;
        return _buildContent(context, user.uid);
      },
    );
  }

  Widget _buildContent(BuildContext context, String userId) {
    final followedAsync = ref.watch(followedNotificationsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Takip Ettiklerim')),
      body: followedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Yüklenemedi: $err')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Henüz takip edilen bildirim yok.'),
            );
          }

          return ListView.builder(
            key: PageStorageKey('followed-$userId'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final AppNotification notification = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                  subtitle: Text(
                    notification.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    notification.statusLabel,
                    style: TextStyle(color: notification.statusColor),
                  ),
                  onTap:
                      () => context.push(
                        '/notification-detail/${notification.id}',
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
