import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseService
/// - Inisialisasi dari variabel environment (dart-define)
/// - Menyediakan helper Realtime untuk comments & presence (typing indicator)
/// - Optional: jika env kosong, `enabled` akan false dan semua method menjadi no-op
class SupabaseService {
  SupabaseService._(this._client);

  final SupabaseClient? _client;

  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envAnon = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<SupabaseService> initialize() async {
    if (_envUrl.isEmpty || _envAnon.isEmpty) {
      return SupabaseService._(null);
    }
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: _envUrl,
        anonKey: _envAnon,
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.warn,
        ),
      );
    }
    return SupabaseService._(Supabase.instance.client);
  }

  bool get enabled => _client != null;
  SupabaseClient get client => _client!;

  // ===== Realtime: Comments =====
  RealtimeChannel? subscribeComments({
    required int postId,
    required void Function(Map<String, dynamic> row) onInsert,
  }) {
    if (!enabled) return null;
    final channel = client.channel('comments_post_$postId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'comments',
      callback: (payload) {
        final record = payload.newRecord;
        final pid = record['post_id'];
        if (pid == postId || pid?.toString() == postId.toString()) {
          onInsert(record);
        }
      },
    );
    channel.subscribe();
    return channel;
  }

  // ===== Presence: Typing indicator =====
  RealtimeChannel? joinTypingRoom({
    required int postId,
    required String userId,
    required String name,
    void Function(Map<String, dynamic> presenceState)? onSync,
  }) {
    if (!enabled) return null;
    final channel = client.channel('typing_post_$postId', opts: const RealtimeChannelConfig(self: true));
    channel.onPresenceSync((_) {
      final dynamic pres = channel.presenceState();
      final names = <String>{};
      try {
        if (pres is Map) {
          for (final entries in pres.values) {
            for (final p in (entries as List)) {
              final payload = (p as dynamic).payload as Map<String, dynamic>?;
              if (payload == null) continue;
              if (payload['typing'] == true) {
                final n = payload['name']?.toString();
                if (n != null && n.isNotEmpty) names.add(n);
              }
            }
          }
        } else if (pres is List) {
          for (final p in pres) {
            final payload = (p as dynamic).payload as Map<String, dynamic>?;
            if (payload == null) continue;
            if (payload['typing'] == true) {
              final n = payload['name']?.toString();
              if (n != null && n.isNotEmpty) names.add(n);
            }
          }
        }
      } catch (_) {}
      onSync?.call({'names': names.toList()});
    });
    channel.subscribe();
    channel.track({
      'user_id': userId,
      'name': name,
      'typing': false,
    });
    return channel;
  }

  Future<void> setTyping(RealtimeChannel channel, {required bool typing}) async {
    try {
      await channel.track({'typing': typing});
    } catch (_) {
      // ignore in no-op
    }
  }
}

final supabaseServiceProvider = FutureProvider<SupabaseService>((ref) async {
  final svc = await SupabaseService.initialize();
  ref.onDispose(() {
    // auto unsubscribe all channels when provider disposed
    try {
      if (svc.enabled) {
        svc.client.removeAllChannels();
      }
    } catch (_) {}
  });
  return svc;
});
