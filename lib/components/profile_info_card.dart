// profile_info_card.dart - profil kartı

import 'package:flutter/material.dart';
import 'package:kampus_bildirim/components/status_tag.dart';
import 'package:kampus_bildirim/models/app_user.dart';

// =============================================================================
// ProfileInfoCard Widget'ı
// =============================================================================
/// Kullanıcı profil bilgilerini gösteren kart.
/// Fotoğraf düzenleme butonu içerir.
class ProfileInfoCard extends StatelessWidget {
  /// Gösterilecek kullanıcı verisi
  final AppUser user;

  /// Fotoğraf düzenleme butonu callback'i (opsiyonel)
  final VoidCallback? onEditImage;

  /// Constructor
  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.onEditImage,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // Gölge efekti
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 184, 180, 180),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ----- PROFİL FOTOĞRAFI -----
          Stack(
            children: [
              // Avatar
              CircleAvatar(
                radius: 35,
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                backgroundImage:
                    user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                // Fotoğraf yoksa varsayılan ikon
                child:
                    user.avatarUrl == null
                        ? Icon(
                          Icons.account_circle_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        )
                        : null,
              ),
              // Fotoğraf değiştirme butonu (sağ altta)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 20),

          // ----- KULLANICI BİLGİLERİ -----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ad Soyad
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                // E-posta
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Rol ve Departman etiketleri
                Wrap(
                  spacing: 8,
                  children: [
                    // Sadece "user" değilse rolü göster
                    if (user.role != "user")
                      StatusTag(text: user.role, color: Colors.red),
                    // Departman varsa göster
                    if (user.department.isNotEmpty)
                      StatusTag(
                        text: user.department,
                        color: Color.fromARGB(255, 223, 182, 125),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
