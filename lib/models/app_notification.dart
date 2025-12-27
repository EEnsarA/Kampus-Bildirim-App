// app_notification.dart
// bildirim modeli - firestore'dan gelen veriler bu modele dönüştürülüyor

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// bildirim türleri
enum NotificationType {
  general,
  emergency,
  lostFound,
  event,
  failure,
  environment,
}

// bildirim durumu
enum NotificationStatus { open, reviewing, resolved }

/// =============================================================================
/// AppNotification Sınıfı
/// =============================================================================
/// Kampüs bildirimlerinin ana veri modelidir.
/// Firestore'daki 'notifications' collection'undaki verileri temsil eder.
/// =============================================================================
class AppNotification {
  // -------------------------------------------------------------------------
  // Temel Bilgiler
  // -------------------------------------------------------------------------
  final String id; // Firestore doküman ID'si
  final String title; // Bildirim başlığı
  final String content; // Bildirim içeriği/açıklaması
  final NotificationType type; // Bildirim türü
  final NotificationStatus status; // Bildirim durumu
  final String? imageUrl; // Opsiyonel resim URL'si

  // -------------------------------------------------------------------------
  // Konum Bilgileri (Harita için)
  // -------------------------------------------------------------------------
  final double latitude; // Enlem koordinatı
  final double longitude; // Boylam koordinatı

  // -------------------------------------------------------------------------
  // Gönderen Bilgileri
  // -------------------------------------------------------------------------
  final String senderId; // Gönderenin kullanıcı ID'si
  final String senderName; // Gönderenin adı
  final String department; // Gönderenin birimi/bölümü

  // -------------------------------------------------------------------------
  // Meta Bilgiler
  // -------------------------------------------------------------------------
  final DateTime createdAt; // Oluşturulma tarihi
  final bool isDeleted; // Soft-delete durumu

  // -------------------------------------------------------------------------
  // Constructor (Yapıcı Metod)
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Türe Göre Renk Getter'ı
  // -------------------------------------------------------------------------
  /// Bildirim türüne göre uygun rengi döndürür.
  /// UI'da tutarlı renk kullanımı için merkezi yönetim sağlar.
  Color get typeColor {
    switch (type) {
      case NotificationType.emergency:
        return Colors.red; // Acil: Kırmızı
      case NotificationType.lostFound:
        return Colors.blue; // Kayıp: Mavi
      case NotificationType.environment:
        return Colors.green; // Çevre: Yeşil
      case NotificationType.general:
        return Colors.grey.shade700; // Genel: Gri
      case NotificationType.failure:
        return Colors.orange; // Arıza: Turuncu
      case NotificationType.event:
        return Colors.deepPurple; // Etkinlik: Mor
    }
  }

  // -------------------------------------------------------------------------
  // Harita İşaretçisi Rengi
  // -------------------------------------------------------------------------
  /// Google Maps işaretçi rengi için HUE değeri döndürür.
  /// BitmapDescriptor sınıfının önceden tanımlı renklerini kullanır.
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

  // -------------------------------------------------------------------------
  // Tür İkonu Getter'ı
  // -------------------------------------------------------------------------
  /// Bildirim türüne göre uygun Material ikonu döndürür.
  IconData get typeIcon {
    switch (type) {
      case NotificationType.emergency:
        return Icons.warning_amber_rounded; // Uyarı
      case NotificationType.lostFound:
        return Icons.search; // Arama
      case NotificationType.event:
        return Icons.event; // Takvim
      case NotificationType.general:
        return Icons.campaign; // Duyuru
      case NotificationType.environment:
        return Icons.maps_home_work_outlined; // Bina
      case NotificationType.failure:
        return Icons.engineering; // Mühendislik
    }
  }

  // -------------------------------------------------------------------------
  // Tür Etiketi Getter'ı
  // -------------------------------------------------------------------------
  /// Bildirim türünü Türkçe okunabilir metin olarak döndürür.
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

  // -------------------------------------------------------------------------
  // Durum Etiketi Getter'ı
  // -------------------------------------------------------------------------
  /// Bildirim durumunu Türkçe okunabilir metin olarak döndürür.
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

  // -------------------------------------------------------------------------
  // Durum Rengi Getter'ı
  // -------------------------------------------------------------------------
  /// Bildirim durumuna göre badge/etiket rengi döndürür.
  Color get statusColor {
    switch (status) {
      case NotificationStatus.open:
        return const Color.fromARGB(255, 197, 42, 42); // Kırmızı
      case NotificationStatus.reviewing:
        return const Color.fromARGB(255, 26, 49, 83); // Lacivert
      case NotificationStatus.resolved:
        return Colors.grey; // Gri
    }
  }

  // =========================================================================
  // Firestore Dönüşüm Metodları
  // =========================================================================

  /// ---------------------------------------------------------------------------
  /// fromMap - Firestore'dan Nesneye Dönüşüm (Factory Constructor)
  /// ---------------------------------------------------------------------------
  /// Firestore dokümanından (Map) AppNotification nesnesine dönüştürür.
  ///
  /// Parametreler:
  /// - map: Firestore'dan gelen key-value veri
  /// - docId: Doküman ID'si (otomatik oluşturulan)
  /// ---------------------------------------------------------------------------
  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',

      // String'i enum'a dönüştür (güvenli arama ile)
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

  /// ---------------------------------------------------------------------------
  /// toMap - Nesneden Firestore'a Dönüşüm
  /// ---------------------------------------------------------------------------
  /// AppNotification nesnesini Firestore'a yazılabilir Map formatına dönüştürür.
  /// Yeni bildirim oluştururken veya güncellerken kullanılır.
  /// ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'type': type.name, // Enum'ı string olarak kaydet
      'status': status.name, // Enum'ı string olarak kaydet
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'senderId': senderId,
      'senderName': senderName,
      'department': department,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(
        createdAt,
      ), // DateTime'ı Timestamp'e çevir
    };
  }
}
