// sender_info_card.dart
// gönderici bilgisi kartı

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';

class SenderInfoCard extends ConsumerWidget {
  final String senderId;

  /// Constructor
  const SenderInfoCard({super.key, required this.senderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kullanıcı verisini ID ile çek
    final senderAsync = ref.watch(userByIdProvider(senderId));

    // AsyncValue pattern - loading/error/data durumlarını ele al
    return senderAsync.when(
      // Yükleniyor durumu
      loading:
          () => Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),

      // Hata durumu - boş widget döndür
      error: (_, __) => const SizedBox(),

      // Veri geldi
      data: (user) {
        // Kullanıcı bulunamadıysa
        if (user == null) return const SizedBox();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              // ----- AVATAR -----
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage:
                    user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                // Avatar yoksa ismin ilk harfini göster
                child:
                    user.avatarUrl == null
                        ? Text(
                          user.name[0].toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                        : null,
              ),

              const SizedBox(width: 15),

              // ----- KULLANICI BİLGİLERİ -----
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Oluşturan:" etiketi
                    Text(
                      "Oluşturan:",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    // Kullanıcı adı
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Departman ve rol
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${user.department}  •  ${user.role.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
