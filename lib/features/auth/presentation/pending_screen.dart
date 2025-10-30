import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forum_alumni/features/auth/application/auth_controller.dart';
import 'package:forum_alumni/features/forum/presentation/home_screen.dart';
import 'login_screen.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  static const String routeName = 'pending';
  static const String routePath = '/pending';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menunggu Verifikasi'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              context.go(LoginScreen.routePath);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top, size: 72, color: Colors.amber),
              const SizedBox(height: 16),
              Text(
                'Akun Anda sedang menunggu verifikasi admin.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Anda akan mendapatkan pemberitahuan setelah verifikasi selesai.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    state.errorMessage!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).refreshProfile();
                  final nextState = ref.read(authNotifierProvider);
                  if (nextState.status == AuthStatus.authenticated) {
                    // ignore: use_build_context_synchronously
                    context.go(HomeScreen.routePath);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Periksa Status Terbaru'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
