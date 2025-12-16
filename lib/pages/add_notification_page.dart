import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';

class AddNotificationPage extends ConsumerStatefulWidget {
  const AddNotificationPage({super.key});

  @override
  ConsumerState<AddNotificationPage> createState() =>
      _AddNotificationPageState();
}

class _AddNotificationPageState extends ConsumerState<AddNotificationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  NotificationType _selectedType = NotificationType.general;

  bool _isloading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.value;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hata: Kullanıcı bilgisi bulunamadı!")),
      );
      return;
    }

    setState(() => _isloading = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('notifications').doc();

      final newNotification = AppNotification(
        id: docRef.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        imageUrl: null,

        latitude: 39.9042,
        longitude: 32.8642,

        senderId: user.uid,
        senderName: user.name,
        department: user.department,

        createdAt: DateTime.now(),
      );

      // 4. Firestore'a Kaydet (.toMap() metodu iş başında)
      await docRef.set(newNotification.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bildirim başarıyla gönderildi! ✅")),
        );
        context.pop(); // Sayfayı kapat, geriye dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
      }
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Bildirim Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- TÜR SEÇİMİ (DROPDOWN) ---
              DropdownButtonFormField<NotificationType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Bildirim Türü",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                // Enum listesini döngüye sokup menü yapıyoruz
                items:
                    NotificationType.values.map((type) {
                      // Geçici bir model oluşturup renk/ikon çekiyoruz (Helper metodları kullanmak için)
                      // Bu biraz trick (hile) ama çok pratik.
                      final temp = AppNotification(
                        id: '',
                        title: '',
                        content: '',
                        type: type,
                        latitude: 0,
                        longitude: 0,
                        senderId: '',
                        senderName: '',
                        department: '',
                        createdAt: DateTime.now(),
                      );

                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              color: temp.typeColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(temp.typeLabel),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Başlık",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) => val!.isEmpty ? "Başlık boş olamaz" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Duyuru İçeriği",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val!.isEmpty ? "İçerik boş olamaz" : null,
              ),

              const SizedBox(height: 24),

              // --- GÖNDER BUTONU ---
              ElevatedButton.icon(
                onPressed: _isloading ? null : _submitForm,
                icon:
                    _isloading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.send),
                label: Text(
                  _isloading ? "Gönderiliyor..." : "BİLDİRİMİ YAYINLA",
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
