import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kampus_bildirim/components/custom_toast.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/repository/notification_repository.dart';
import 'package:kampus_bildirim/services/location_service.dart';
import 'package:kampus_bildirim/services/store_img_service.dart';

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

  // Image
  File? _selectedImage;

  // Konum
  double? _latitude;
  double? _longitude;
  bool _isLocationLoading = false;
  String? _currentAdress;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      final position = await LocationService.getCurrentLocation();

      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentAdress = address;
      });

      if (mounted) {
        showCustomToast(context, "Konum başarıyla alındı! : $address 📍");
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  // image_picker kütüpphanesi ile galeriden img alma
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final userAsync = ref.read(userProfileProvider);
    final user = userAsync.value;

    if (user == null) {
      showCustomToast(
        context,
        "Hata : kullanıcı bilgisi bulunamadı!",
        isError: true,
      );
      return;
    }

    setState(() => _isloading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await StoreImgService.uploadNotificationImage(
          _selectedImage!,
        );
      }

      final repository = ref.read(notificationRepositoryProvider);

      // Repository üzerinden bildirim oluştur
      await repository.createNotification(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        latitude: _latitude ?? 39.9042,
        longitude: _longitude ?? 32.8642,
        senderId: user.uid,
        senderName: user.fullName,
        department: user.department,
        imageUrl: imageUrl,
      );

      if (mounted) {
        FocusScope.of(context).unfocus();
        showCustomToast(context, "Bildirim başarıyla gönderildi! 🚀");
        context.pop();
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
      appBar: AppBar(
        title: const Text(
          "Yeni Bildirim Ekle",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<NotificationType>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Bildirim Türü",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                items:
                    NotificationType.values.map((type) {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Konum Bilgisi",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentAdress != null
                                ? _currentAdress!
                                : (_latitude != null
                                    ? "Koordinat: ${_latitude!.toStringAsFixed(4)}, ..."
                                    : "Henüz konum alınamadı"),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isLocationLoading ? null : _getCurrentLocation,
                      icon:
                          _isLocationLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                Icons.my_location,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      tooltip: "Konumu Güncelle",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Başlık",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.title,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                validator: (val) => val!.isEmpty ? "Başlık boş olamaz" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: "Duyuru İçeriği",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.description,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val!.isEmpty ? "İçerik boş olamaz" : null,
              ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(),
                    image:
                        _selectedImage != null
                            ? DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _selectedImage == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Resim Ekle",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                          : Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isloading ? null : _submitForm,
                icon:
                    _isloading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.arrow_forward_ios),
                label: Text(
                  _isloading ? "Gönderiliyor..." : "BİLDİRİMİ YAYINLA",
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
