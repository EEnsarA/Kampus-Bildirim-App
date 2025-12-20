import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/components/notification_status_badge.dart';
import 'package:kampus_bildirim/components/sender_info_card.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/services/notification_service.dart';

class NotificationDetailPage extends ConsumerStatefulWidget {
  final AppNotification notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  ConsumerState<NotificationDetailPage> createState() =>
      _NotificationDetailPageState();
}

class _NotificationDetailPageState
    extends ConsumerState<NotificationDetailPage> {
  Future<void> _deleteNotification() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Bildirimi Sil"),
            content: const Text(
              "Bu bildirimi kalıcı olarak silmek istediğine emin misin?",
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text("İptal"),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: const Text("Sil", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final notificationService = ref.read(notificationServiceProvider);

      await notificationService.deleteNotification(
        widget.notification.id,
        widget.notification.imageUrl,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bildirim silindi"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  void _editNotification() {
    // Düzenleme sayfasına (Form sayfasına) mevcut veriyi göndererek git
    // context.push('/edit-notification', extra: widget.notification);
    print("Düzenleme sayfasına gidilecek");
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.notification.createdAt;
    final formattedDate =
        "${date.day}/${date.month} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    final userAsync = ref.watch(userProfileProvider);
    bool isAdmin = false;

    userAsync.whenData((user) {
      if (user != null) {
        if (user.role == "admin") {
          isAdmin = true;
        }
      }
    });

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
        actions:
            isAdmin
                ? [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editNotification();
                      if (value == 'delete') _deleteNotification();
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue),
                                SizedBox(width: 8),
                                Text("Düzenle"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Sil"),
                              ],
                            ),
                          ),
                        ],
                  ),
                ]
                : null,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Ekran kaydırılabilir olsa bile en az ekran boyu kadar yer kaplasın diyoruz
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. RESİM ALANI
                      if (widget.notification.imageUrl != null)
                        Container(
                          width: double.infinity,
                          height: 200,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.notification.imageUrl!,
                              ),
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
                            color: widget.notification.typeColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              widget.notification.typeIcon,
                              size: 50,
                              color: widget.notification.typeColor,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NotificationStatusBadge(
                            notification: widget.notification,
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Text(
                        widget.notification.title,
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
                            widget.notification.typeIcon,
                            color: widget.notification.typeColor,
                            size: 24,
                          ),
                          const SizedBox(width: 10),

                          Text(
                            widget.notification.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: widget.notification.typeColor,
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

                      Text(
                        widget.notification.content,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),

                      const Spacer(),

                      const SizedBox(height: 20),

                      SenderInfoCard(senderId: widget.notification.senderId),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/map', extra: widget.notification);
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
