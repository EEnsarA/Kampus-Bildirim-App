/// =============================================================================
/// KAMPÜS BİLDİRİM - Admin İşlemleri Logları (admin_actions_page.dart)
/// =============================================================================
/// Bu dosya admin kullanıcıların yaptığı işlemlerin
/// loglarını gösteren sayfayı içerir.
///
/// Görüntülenen Bilgiler:
/// - İşlem tipi (durum güncelleme, silme vb.)
/// - İşlemi yapan admin
/// - İlgili bildirim ID'si
/// - İşlem zamanı
///
/// Öğrenci Projesi - Mobil Programlama Dersi
/// =============================================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// AdminActionsPage Widget'ı
// =============================================================================
/// Admin işlem loglarını gösteren sayfa.
/// StreamBuilder ile gerçek zamanlı güncellenir.
class AdminActionsPage extends StatelessWidget {
  const AdminActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin İşlemleri Logları')),
      body: StreamBuilder<QuerySnapshot>(
        // Firestore'dan logları zaman sırasına göre çek
        stream:
            FirebaseFirestore.instance
                .collection('admin_actions')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          // Yükleniyor
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Veri yok
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz kayıt yok'));
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final timestamp = (data['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                // İşlem tipi
                title: Text(data['action'] ?? '—'),
                // Admin adı ve bildirim ID
                subtitle: Text(
                  '${data['adminName'] ?? data['adminId'] ?? '—'} • ${data['notificationId'] ?? ''}',
                ),
                // Tarih/saat
                trailing: Text(
                  timestamp != null
                      ? '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                      : '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
