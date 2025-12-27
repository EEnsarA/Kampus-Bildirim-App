/// =============================================================================
/// KAMPÜS BİLDİRİM - Harita Bildirim Kartı (map_notification_card.dart)
/// =============================================================================
/// Bu dosya harita sayfasında marker'a tıklandığında gösterilen
/// bildirim önizleme kartını içerir.
///
/// Özellikler:
/// - Bildirim tipi, başlık ve içerik gösterimi
/// - "Ne kadar önce" formatında zaman gösterimi
/// - Detay sayfasına yönlendirme butonu
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

// =============================================================================
// MapNotificationCard Widget'ı
// =============================================================================
/// Haritada marker'a tıklandığında gösterilen kart.
/// StatelessWidget - Sadece görüntüleme amaçlı, state tutmaz.
class MapNotificationCard extends StatelessWidget {
  /// Gösterilecek bildirim verisi
  final AppNotification notification;

  /// Detay butonuna basıldığında çalışacak callback
  final VoidCallback onDetailPressed;

  /// Constructor
  const MapNotificationCard({
    super.key,
    required this.notification,
    required this.onDetailPressed,
  });

  // -------------------------------------------------------------------------
  // Zaman Formatlama Yardımcı Metodu
  // -------------------------------------------------------------------------
  /// Tarihi "X dk/saat/gün önce" formatına çevirir.
  /// Kullanıcı dostu zaman gösterimi sağlar.
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }

  // -------------------------------------------------------------------------
  // Widget Build Metodu
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10, // Belirgin gölge efekti
      margin: EdgeInsets.zero, // Positioned içinde margin gereksiz
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- ÜST SATIR: Tip ve Zaman -----
            Row(
              children: [
                // Bildirim tipi ikonu
                Icon(
                  notification.typeIcon,
                  color: notification.typeColor,
                  size: 20,
                ),
                const SizedBox(width: 5),
                // Bildirim tipi etiketi
                Text(
                  notification.typeLabel.toUpperCase(),
                  style: TextStyle(
                    color: notification.typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Oluşturulma zamanı
                Text(
                  _timeAgo(notification.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ----- BAŞLIK -----
            Text(
              notification.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // Uzun başlıkları kes
            ),
            const SizedBox(height: 5),

            // ----- İÇERİK ÖNİZLEME -----
            Text(
              notification.content,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 15),

            // ----- DETAY BUTONU -----
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
