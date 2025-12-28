import 'package:flutter/material.dart';
import 'package:kampus_bildirim/components/sender_info_card.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

class MapNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onDetailPressed;

  const MapNotificationCard({
    super.key,
    required this.notification,
    required this.onDetailPressed,
  });

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      margin:
          EdgeInsets.zero, // Positioned içinde olduğu için margin'e gerek yok
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // İçerik kadar yer kapla display filled
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  notification.typeIcon,
                  color: notification.typeColor,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  notification.typeLabel.toUpperCase(),
                  style: TextStyle(
                    color: notification.typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _timeAgo(notification.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              notification.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),

            Text(
              notification.content,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            SenderInfoCard(senderId: notification.senderId),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: notification.typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onDetailPressed,
                child: const Text("Detayı Gör"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
