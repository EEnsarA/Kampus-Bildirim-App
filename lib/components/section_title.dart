// section_title.dart - bölüm başlığı

import 'package:flutter/material.dart';

// =============================================================================
// SectionTitle Widget'ı
// =============================================================================
/// Sayfaları bölümlere ayırmak için kullanılan başlık.
/// Soldan hizalı, kalın yazı tipli.
class SectionTitle extends StatelessWidget {
  /// Başlık metni
  final String title;

  /// Constructor
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
