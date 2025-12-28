import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kampus_bildirim/components/custom_toast.dart';
import 'package:kampus_bildirim/components/profile_info_card.dart';
import 'package:kampus_bildirim/components/section_title.dart';
import 'package:kampus_bildirim/models/app_user.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/services/auth_service.dart';
import 'package:kampus_bildirim/services/store_img_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _notifyEvents = true;
  bool _notifyUrgent = true;
  bool _notifyLostFound = false;

  Future<void> _pickAndUploadImage(String userId) async {
    final picker = ImagePicker();
    // 1. Resim Seç
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 500,
    );

    if (pickedFile == null) return;

    try {
      if (mounted) {
        showCustomToast(context, "Profil resmi yükleniyor...", isError: false);
      }
      File file = File(pickedFile.path);
      String? downloadUrl = await StoreImgService.uploadProfileImage(
        file,
        userId,
      );

      if (downloadUrl != null) {
        await FirebaseFirestore.instance.collection("users").doc(userId).update(
          {"avatarUrl": downloadUrl},
        );

        if (mounted) {
          showCustomToast(
            context,
            "Profil resmi başarıyla güncellendi!",
            isError: false,
          );
        }
      } else {
        throw Exception("Resim yüklenemedi, URL boş döndü.");
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Bir hata oluştu: $e", isError: true);
      }
    }
  }

  // Ad soyad düzenleme dialogu
  Future<void> _showEditNameDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final surnameController = TextEditingController(text: user.surname);

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Profil Bilgilerini Düzenle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: surnameController,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );

    if (result == true) {
      final newName = nameController.text.trim();
      final newSurname = surnameController.text.trim();

      if (newName.isEmpty || newSurname.isEmpty) {
        if (mounted) {
          showCustomToast(context, 'Ad ve soyad boş olamaz', isError: true);
        }
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'name': newName, 'surname': newSurname});

        if (mounted) {
          showCustomToast(context, 'Profil bilgileri güncellendi!');
        }
      } catch (e) {
        if (mounted) {
          showCustomToast(context, 'Hata: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profil Ve Ayarlar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: Colors.grey.shade100,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Hata : $err")),
        data: (AppUser? user) {
          if (user == null) {
            return const Center(child: Text("Kullanıcı Bulunamadı"));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ProfileInfoCard(
                  user: user,
                  onEditImage: () => _pickAndUploadImage(user.uid),
                  onEditName: () => _showEditNameDialog(user),
                ),
                const SizedBox(height: 20),
                const SectionTitle(title: "Bildirim Tercihleri"),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text("Etkinlik Bildirimleri"),
                        subtitle: const Text(
                          "Kampüs etkinliklerinden haberdar ol",
                        ),
                        secondary: const Icon(
                          Icons.event,
                          color: Colors.deepPurple,
                        ),
                        value: _notifyEvents,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) => setState(() => _notifyEvents = val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text("Acil Durumlar"),
                        subtitle: const Text("Önemli uyarılarda bildirim al"),
                        secondary: const Icon(
                          Icons.warning_amber,
                          color: Colors.red,
                        ),
                        value: _notifyUrgent,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) => setState(() => _notifyUrgent = val),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text("Kayıp / Buluntu"),
                        secondary: const Icon(Icons.search, color: Colors.blue),
                        value: _notifyLostFound,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged:
                            (val) => setState(() => _notifyLostFound = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionTitle(title: "Takip Ettiklerim"),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark, color: Colors.orange),
                    ),
                    title: const Text("Takip Edilen Bildirimler"),
                    subtitle: const Text("İlgilendiğin gönderileri gör"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      context.push('/followed');
                    },
                  ),
                ),
                const SizedBox(height: 30),

                // Admin paneline erişim (sadece admin'ler görsün)
                if (user.role == 'admin')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade50,
                        foregroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.push('/admin');
                      },
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text(
                        "Admin Paneline Git",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      "Çıkış Yap",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
