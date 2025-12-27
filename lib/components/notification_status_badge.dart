// notification_status_badge.dart - durum rozeti

import 'package:flutter/material.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

// =============================================================================
// NotificationStatusBadge Widget'ı
// =============================================================================
/// Bildirim durumunu görsel olarak gösteren rozet.
/// Her durum için farklı renk kullanılır (model'daki statusColor).
class NotificationStatusBadge extends StatelessWidget {
  /// Durum bilgisi alınacak bildirim
  final AppNotification notification;

  /// Constructor
  const NotificationStatusBadge({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // Hafif arka plan rengi (durum renginin %10'u)
        color: notification.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        // Kenarlık (durum renginin %50'si)
        border: Border.all(
          color: notification.statusColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        notification.statusLabel, // "Aktif", "Çözüldü" vb.
        style: TextStyle(
          color: notification.statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
