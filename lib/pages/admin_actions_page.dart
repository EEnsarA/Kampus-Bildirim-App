import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActionsPage extends StatelessWidget {
  const AdminActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin İşlemleri Logları')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('admin_actions')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
                title: Text(data['action'] ?? '—'),
                subtitle: Text(
                  '${data['adminName'] ?? data['adminId'] ?? '—'} • ${data['notificationId'] ?? ''}',
                ),
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
