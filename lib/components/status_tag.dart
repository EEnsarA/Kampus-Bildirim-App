// status_tag.dart - küçük etiket widget

import 'package:flutter/material.dart';

// =============================================================================
// StatusTag Widget'ı
// =============================================================================
/// Renkli arka planlı, küçük boyutlu etiket bileşeni.
/// Profil sayfasında rol ve departman gösterimi için kullanılır.
class StatusTag extends StatelessWidget {
  /// Etiket metni
  final String text;

  /// Etiket rengi (arka plan ve kenarlık)
  final Color color;

  /// Constructor
  const StatusTag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Hafif arka plan (rengin %10'u)
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        // Kenarlık
        border: Border.all(color: color.withValues()),
      ),
      child: Text(
        text.toUpperCase(), // Büyük harfle göster
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
