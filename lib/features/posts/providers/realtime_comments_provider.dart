import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/supabase_service.dart';
import '../models/comment.dart';
import '../../auth/models/user.dart';
import 'post_feed_provider.dart';
import '../../../services/notification_service.dart';

class RealtimeCommentsController extends StateNotifier<List<Comment>> {
  RealtimeCommentsController(this.ref, {required this.postId}) : super(const []) {
    _init();
  }

  final Ref ref;
  final String postId;
  StreamSubscription? _sub;

  Future<void> _init() async {
    // Load awal dari provider lama (mock API)
    final initial = await ref.read(commentsProvider(postId).future);
    state = initial;

    // Subscribe supabase jika tersedia dan postId numerik
    final svc = await ref.read(supabaseServiceProvider.future);
    if (!svc.enabled) return;

    final int? pid = int.tryParse(postId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (pid == null) return;

    final ch = svc.subscribeComments(
      postId: pid,
      onInsert: (row) {
        // Map row supabase ke model Comment sederhana
        final c = Comment(
          id: (row['id'] ?? '').toString(),
          postId: postId,
          parentId: row['parent_id']?.toString(),
          author: User(
            id: (row['user_id'] ?? 'unk').toString(),
            name: 'Pengguna',
            email: 'user@example.com',
          ),
          contentMarkdown: (row['content'] ?? '').toString(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
        state = [c, ...state];
        // Local notif dengan deep-link ke post detail
        final notif = ref.read(notificationServiceProvider);
        notif.showLocal(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: 'Komentar baru',
          body: c.contentMarkdown,
          routePayload: '/posts/$postId',
          data: {'title': 'Komentar baru', 'body': c.contentMarkdown},
        );
      },
    );

    // keep channel reference via ref.onDispose
    ref.onDispose(() {
      try {
        ch?.unsubscribe();
      } catch (_) {}
      _sub?.cancel();
    });
  }
}

final realtimeCommentsProvider = StateNotifierProvider.family<RealtimeCommentsController, List<Comment>, String>((ref, postId) {
  return RealtimeCommentsController(ref, postId: postId);
});
