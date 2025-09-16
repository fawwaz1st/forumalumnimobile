import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// NotificationService membungkus flutter_local_notifications dan
/// mengelola permission flow + deep link payload.
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _payloadController = StreamController<String>.broadcast();

  Stream<String> get payloadStream => _payloadController.stream;

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final settings = const InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _payloadController.add(payload);
        }
      },
    );
  }

  Future<bool> ensurePermission(BuildContext context) async {
    // Android 13+ (POST_NOTIFICATIONS)
    var status = await Permission.notification.status;
    if (status.isGranted) return true;

    // Jelaskan alasan
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izin Notifikasi'),
        content: const Text(
          'Kami membutuhkan izin untuk mengirimkan pemberitahuan tentang balasan, mention, dan update penting. '
          'Anda bisa mengatur preferensi kategori notifikasi kapan saja di Pengaturan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Nanti')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Lanjut')),
        ],
      ),
    );
    if (ok != true) return false;

    status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> showLocal({
    required int id,
    required String title,
    required String body,
    String? routePayload,
    Map<String, dynamic>? data,
    String channelId = 'default_channel',
    String channelName = 'General',
  }) async {
    final payload = jsonEncode({'route': routePayload, 'data': data});

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'General',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      channelDescription: 'Notifikasi umum Forum Alumni',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin.show(id, title, body, details, payload: payload);
  }

  // Catatan: badge app icon memerlukan plugin terpisah (mis. flutter_app_badger).
  // Kita sediakan no-op agar mudah dikembangkan kemudian.
  Future<void> setBadgeCount(int count) async {}
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final svc = NotificationService();
  // init once
  unawaited(svc.init());
  ref.onDispose(() {
    // nothing
  });
  return svc;
});
