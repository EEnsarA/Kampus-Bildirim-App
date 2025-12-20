import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum NotificationType {
  general,
  emergency,
  lostFound,
  event,
  failure,
  environment,
}

enum NotificationStatus { open, reviewing, resolved }

class AppNotification {
  final String id;
  final String title;
  final String content;
  final NotificationType type;
  final NotificationStatus status;
  final String? imageUrl;

  final double latitude;
  final double longitude;

  final String senderId;
  final String senderName;
  final String department;

  final DateTime createdAt;
  final bool isDeleted;

  //ctor
  AppNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    this.status = NotificationStatus.open,
    required this.latitude,
    required this.longitude,
    required this.senderId,
    required this.senderName,
    required this.department,
    required this.createdAt,
    this.isDeleted = false,
  });

  Color get typeColor {
    switch (type) {
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.lostFound:
        return Colors.blue;
      case NotificationType.environment:
        return Colors.green;
      case NotificationType.general:
        return Colors.grey.shade700;
      case NotificationType.failure:
        return Colors.orange;
      case NotificationType.event:
        return Colors.deepPurple;
    }
  }

  // google map için konum renkleri
  double get markerHue {
    switch (type) {
      case NotificationType.emergency:
        return BitmapDescriptor.hueRed;
      case NotificationType.lostFound:
        return BitmapDescriptor.hueBlue;
      case NotificationType.environment:
        return BitmapDescriptor.hueGreen;
      case NotificationType.failure:
        return BitmapDescriptor.hueOrange;
      case NotificationType.event:
        return BitmapDescriptor.hueViolet;
      case NotificationType.general:
        return BitmapDescriptor.hueAzure;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.emergency:
        return Icons.warning_amber_rounded;
      case NotificationType.lostFound:
        return Icons.search;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.general:
        return Icons.campaign;
      case NotificationType.environment:
        return Icons.maps_home_work_outlined;
      case NotificationType.failure:
        return Icons.engineering;
    }
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.emergency:
        return "ACİL DURUM";
      case NotificationType.lostFound:
        return "Kayıp / Buluntu";
      case NotificationType.event:
        return "Etkinlik";
      case NotificationType.general:
        return "Genel Duyuru";
      case NotificationType.failure:
        return "Arıza";
      case NotificationType.environment:
        return "Çevresel";
    }
  }

  String get statusLabel {
    switch (status) {
      case NotificationStatus.open:
        return "Açık";
      case NotificationStatus.reviewing:
        return "İnceleniyor";
      case NotificationStatus.resolved:
        return "Çözüldü";
    }
  }

  Color get statusColor {
    switch (status) {
      case NotificationStatus.open:
        return Color.fromARGB(255, 223, 182, 125);
      case NotificationStatus.reviewing:
        return Colors.orange;
      case NotificationStatus.resolved:
        return Colors.grey;
    }
  }

  // firestore map => AppNotification Çevirme
  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',

      // String olarak gelen tür bilgisini enum type'a çevirme
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'general'),
        orElse: () => NotificationType.general,
      ),

      status: NotificationStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'open'),
        orElse: () => NotificationStatus.open,
      ),

      imageUrl: map['imageUrl'],

      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),

      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? 'Bilinmeyen',
      department: map['department'] ?? 'Genel',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: map['isDeleted'] == true,
    );
  }

  //  AppNotification => Firestore map çevirme
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'type': type.name,
      'status': status.name,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'senderId': senderId,
      'senderName': senderName,
      'department': department,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
