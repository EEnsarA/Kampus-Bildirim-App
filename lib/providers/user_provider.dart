// user_provider.dart
// kullanıcı state'i riverpod ile yönetiliyor

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_user.dart';

// auth durumunu dinle
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// =============================================================================
// KULLANICI PROFİLİ PROVIDER
// =============================================================================
/// Giriş yapmış kullanıcının Firestore profilini gerçek zamanlı dinler.
///
/// Nasıl Çalışır:
/// 1. Önce authStateProvider'dan kullanıcı UID'sini alır
/// 2. Sonra Firestore'daki users collection'undan profili çeker
///
/// async* / yield (Stream): Fonksiyon kapanmaz, veri geldiğinde tetiklenir
/// yield*: Pointer gibi - nesneyi değil referansı verir
///
/// NOT: autoDispose KULLANILMADI çünkü sayfa değişikliklerinde
/// provider'ın yeniden oluşturulması loading döngüsüne neden oluyordu.
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  // Auth durumunu dinle
  final authState = ref.watch(authStateProvider);

  // Auth henüz yükleniyorsa veya hatalıysa boş stream dön
  if (authState.isLoading || authState.hasError) {
    return const Stream.empty();
  }

  // Kullanıcı giriş yapmamışsa null dön
  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }

  // Firestore'dan kullanıcı profilini dinle
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return AppUser.fromMap(snapshot.data()!, user.uid);
      });
});

// =============================================================================
// ID İLE KULLANICI GETİRME PROVIDER'I
// =============================================================================
/// Belirli bir kullanıcıyı UID ile Firestore'dan getirir.
/// Bildirim gönderen bilgisini göstermek için kullanılır.
///
/// Kullanım: ref.watch(userByIdProvider('user_uid'))
final userByIdProvider = FutureProvider.family<AppUser?, String>((
  ref,
  userId,
) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(userId).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  } catch (e) {
    return null;
  }
});
