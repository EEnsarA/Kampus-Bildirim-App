import 'package:flutter/material.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

class NotificationStatusBadge extends StatelessWidget {
  final AppNotification notification;

  const NotificationStatusBadge({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: notification.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: notification.statusColor.withValues(alpha: 0.5),
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
    );
  }
}
