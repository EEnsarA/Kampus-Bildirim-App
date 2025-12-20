import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_user.dart';

// ref (referans) parametresi : Riverpod parametresi ref.watch , ref.read yapılabilmesi için
// Klasik template fonksiyonu <User?> User type gelebilir null da olabilir (?)

// o anki auth bilgisi döner .
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// async* / yield (Stream): Fonksiyon return gibi kapanmaz arka planda kalır ancak veri geldiğinde tetiklenir
// yield* : pointer gibi düşünülebilir nesneyi değil referansı verilir .

// o auth bilgisine göre dönen uid ile eşleşen users collectiondaki user'ı döner .
// NOT: autoDispose kaldırıldı çünkü sayfa değişikliklerinde provider'ın yeniden oluşturulması
// loading döngüsüne neden oluyordu. Kullanıcı oturumu boyunca state korunmalı.
final userProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.isLoading || authState.hasError) {
    return const Stream.empty();
  }

  final user = authState.value;
  if (user == null) {
    return Stream.value(null);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return AppUser.fromMap(snapshot.data()!, user.uid);
      });
});
