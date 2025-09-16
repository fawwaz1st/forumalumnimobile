import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../services/notification_service.dart';
import 'providers/notifications_provider.dart';

class NotificationPayloadListener extends ConsumerStatefulWidget {
  const NotificationPayloadListener({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<NotificationPayloadListener> createState() => _NotificationPayloadListenerState();
}

class _NotificationPayloadListenerState extends ConsumerState<NotificationPayloadListener> {
  late final _sub = ref.read(notificationServiceProvider).payloadStream.listen((payload) {
    // Simpan ke daftar notifikasi lokal
    ref.read(notificationsControllerProvider.notifier).ingestPayload(payload);

    // Deep link jika ada rute
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final route = map['route'] as String?;
      if (route != null && route.isNotEmpty && mounted) {
        context.go(route);
      }
    } catch (_) {}
  });

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
