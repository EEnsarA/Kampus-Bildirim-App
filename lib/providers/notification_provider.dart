import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kampus_bildirim/models/app_notification.dart';

final searchFilterProvider = StateProvider<String>((ref) => "");

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  return FirebaseFirestore.instance
      .collection("notifications")
      .orderBy("createdAt", descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return AppNotification.fromMap(data, doc.id);
        }).toList();
      });
});
