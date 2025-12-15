import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kampus_bildirim/models/app_user.dart';

// ref (referans) parametresi : Riverpod parametresi ref.watch , ref.read yapılabilmesi için
// Klasik template fonksiyonu <User?> User type gelebilir null da olabilir (?)

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// async* / yield (Stream): Fonksiyon return gibi kapanmaz arka planda kalır ancak veri geldiğinde tetiklenir
// yield* : pointer gibi düşünülebilir nesneyi değil referansı verilir .

final userProfileProvider = StreamProvider.autoDispose<AppUser?>((ref) {
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
