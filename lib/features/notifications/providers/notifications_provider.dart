import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? route;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime timestamp;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.route,
    this.data,
    this.read = false,
    required this.timestamp,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        route: route,
        data: data,
        read: read ?? this.read,
        timestamp: timestamp,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'route': route,
        'data': data,
        'read': read,
        'ts': timestamp.toIso8601String(),
      };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        route: m['route'] as String?,
        data: (m['data'] as Map?)?.cast<String, dynamic>(),
        read: m['read'] == true,
        timestamp: DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
      );
}

class NotificationsController extends StateNotifier<List<AppNotification>> {
  NotificationsController(this._box) : super(const []) {
    _load();
  }

  final Box<String> _box;

  Future<void> _load() async {
    final raw = _box.get('list_v1');
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        state = list.map(AppNotification.fromMap).toList();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    await _box.put('list_v1', jsonEncode(state.map((e) => e.toMap()).toList()));
  }

  int get unreadCount => state.where((e) => !e.read).length;

  void add(AppNotification n) {
    state = [n, ...state];
    _save();
  }

  void markRead(String id) {
    state = state.map((e) => e.id == id ? e.copyWith(read: true) : e).toList();
    _save();
  }

  void markAllRead() {
    state = state.map((e) => e.copyWith(read: true)).toList();
    _save();
  }

  // convenience for payload from NotificationService
  void ingestPayload(String payload) {
    try {
      final obj = jsonDecode(payload) as Map<String, dynamic>;
      final route = obj['route'] as String?;
      final data = (obj['data'] as Map?)?.cast<String, dynamic>();
      final title = data?['title'] as String? ?? 'Notifikasi';
      final body = data?['body'] as String? ?? '';
      final id = 'n_${DateTime.now().millisecondsSinceEpoch}';
      add(AppNotification(
        id: id,
        title: title,
        body: body,
        route: route,
        data: data,
        timestamp: DateTime.now(),
      ));
    } catch (_) {}
  }
}

final _notificationsBoxProvider = FutureProvider<Box<String>>((ref) async {
  return Hive.isBoxOpen('notifications_v1')
      ? Hive.box<String>('notifications_v1')
      : await Hive.openBox<String>('notifications_v1');
});

final notificationsControllerProvider = StateNotifierProvider<NotificationsController, List<AppNotification>>((ref) {
  final boxAsync = ref.watch(_notificationsBoxProvider);
  return boxAsync.maybeWhen(
    data: (box) => NotificationsController(box),
    orElse: () => NotificationsController(Hive.box<String>('notifications_v1')),
  );
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsControllerProvider);
  return list.where((e) => !e.read).length;
});
