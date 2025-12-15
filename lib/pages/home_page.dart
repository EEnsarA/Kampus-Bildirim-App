import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kampus_bildirim/models/app_user.dart';
import 'package:kampus_bildirim/providers/user_provider.dart';
import 'package:kampus_bildirim/services/auth_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //ref (providers)
    final userProfileAsync = ref.watch(userProfileProvider);
    final authService = ref.watch(authServiceProvider);

    return userProfileAsync.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (err, stack) => Scaffold(body: Center(child: Text('Hata: $err'))),

      data: (AppUser? user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                Text(
                  user.department,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () async {
                  authService.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: Icon(Icons.logout),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.role == 'admin') ...[
                  // user.role (TYPE SAFE!)
                  // ... Admin widgetları ...
                  const Text("YÖNETİCİ", style: TextStyle(color: Colors.red)),
                ],
                const Text("Bildirim Listesi..."),
              ],
            ),
          ),
        );
      }, // data
    ); // userProfileAsync
  }
}
