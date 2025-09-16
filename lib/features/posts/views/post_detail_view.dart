import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../providers/post_feed_provider.dart';
import '../models/post.dart';
import '../../auth/models/user.dart' as app_user;
import '../data/posts_repository.dart';
import '../providers/realtime_comments_provider.dart';
import '../models/comment.dart';
import '../../auth/providers/auth_controller.dart';
import '../../../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/utils/sanitize.dart';

class PostDetailView extends ConsumerWidget {
  const PostDetailView({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postByIdProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final url = 'https://forum.example.com/posts/$id';
              Share.share('Lihat diskusi ini: $url');
            },
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat: $e')),
        data: (post) => _PostDetailBody(post: post, postId: id),
      ),
    );
  }
}

class _PostDetailBody extends ConsumerStatefulWidget {
  const _PostDetailBody({required this.post, required this.postId});
  final Post post;
  final String postId;

  @override
  ConsumerState<_PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends ConsumerState<_PostDetailBody> {
  RealtimeChannel? _typingChannel;
  List<String> _typingNames = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final svc = await ref.read(supabaseServiceProvider.future);
      if (!svc.enabled) return;
      final me = ref.read(authControllerProvider).valueOrNull;
      final pid = int.tryParse(widget.postId.replaceAll(RegExp(r'[^0-9]'), ''));
      if (pid == null) return;
      _typingChannel = svc.joinTypingRoom(
        postId: pid,
        userId: me?.id ?? 'guest',
        name: me?.name ?? 'Tamu',
        onSync: (state) {
          final names = (state['names'] as List?)?.cast<String>() ?? const [];
          if (mounted) setState(() => _typingNames = names);
        },
      );
    });
  }

  @override
  void dispose() {
    try {
      _typingChannel?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(realtimeCommentsProvider(widget.postId));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.post.author.avatar != null ? CachedNetworkImageProvider(widget.post.author.avatar!) : null,
              child: widget.post.author.avatar == null ? const Icon(Icons.person, size: 18) : null,
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _showAuthorSheet(context, widget.post.author),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.post.author.name, style: Theme.of(context).textTheme.titleSmall),
                  Text('@${widget.post.author.email.split('@').first}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Hero(
          tag: 'post_title_${widget.post.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(widget.post.title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        const SizedBox(height: 8),
        Markdown(
          selectable: true,
          data: sanitizeMarkdown(widget.post.contentMarkdown),
          softLineBreak: true,
          shrinkWrap: true,
          extensionSet: md.ExtensionSet.gitHubWeb,
          imageBuilder: (uri, title, alt) => LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
              final cacheW = (width * MediaQuery.of(context).devicePixelRatio).round();
              return CachedNetworkImage(
                imageUrl: uri.toString(),
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                filterQuality: FilterQuality.low,
                memCacheWidth: cacheW,
                placeholder: (context, url) => Container(
                  height: 160,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Komentar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            if (_typingNames.isNotEmpty)
              Expanded(
                child: Text(
                  '${_typingNames.join(', ')} mengetik…',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _CommentsThread(
          postId: widget.postId,
          comments: comments,
          onTypingChanged: (isTyping) async {
            final svc = await ref.read(supabaseServiceProvider.future);
            if (_typingChannel != null && svc.enabled) {
              await svc.setTyping(_typingChannel!, typing: isTyping);
            }
          },
        ),
      ],
    );
  }

  void _showAuthorSheet(BuildContext context, app_user.User author) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: author.avatar != null ? CachedNetworkImageProvider(author.avatar!) : null,
                child: author.avatar == null ? const Icon(Icons.person, size: 28) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    if (author.bio != null) Text(author.bio!),
                    const SizedBox(height: 6),
                    Text(author.email, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentsThread extends ConsumerStatefulWidget {
  const _CommentsThread({required this.postId, required this.comments, this.onTypingChanged});
  final String postId;
  final List<Comment> comments; // Comment
  final void Function(bool isTyping)? onTypingChanged;

  @override
  ConsumerState<_CommentsThread> createState() => _CommentsThreadState();
}

class _CommentsThreadState extends ConsumerState<_CommentsThread> {
  final Map<String, bool> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in widget.comments) _CommentItem(
          comment: c,
          level: 0,
          collapsed: _collapsed[c.id] ?? false,
          onToggle: () => setState(() => _collapsed[c.id] = !(_collapsed[c.id] ?? false)),
          onReply: () => _onReply(context, c.id),
          buildChild: (child) => _buildChildren(child, 1),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _onReply(context, null),
            icon: const Icon(Icons.reply_outlined),
            label: const Text('Tambah Komentar'),
          ),
        )
      ],
    );
  }

  Widget _buildChildren(Comment c, int level) {
    if (c.replies.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * level),
      child: Column(
        children: [
          for (final r in c.replies)
            _CommentItem(
              comment: r,
              level: level,
              collapsed: _collapsed[r.id] ?? false,
              onToggle: () => setState(() => _collapsed[r.id] = !(_collapsed[r.id] ?? false)),
              onReply: () => _onReply(context, r.id),
              buildChild: (child) => _buildChildren(child, level + 1),
            ),
        ],
      ),
    );
  }

  Future<void> _onReply(BuildContext context, String? parentId) async {
    final controller = TextEditingController();
    final res = await showModalBottomSheet<String?> (
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Balasan',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  widget.onTypingChanged?.call(v.trim().isNotEmpty);
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Kirim'),
                ),
              )
            ],
          ),
        );
      },
    );

    if (res != null && res.isNotEmpty) {
      await ref.read(postsRepositoryProvider).addReply(
        postId: widget.postId,
        parentId: parentId,
        contentMarkdown: sanitizeMarkdown(res),
      );
      if (mounted) {
        // comments now live via realtime; optionally show local insertion done in repo
      }
    }
    // stop typing when closing
    widget.onTypingChanged?.call(false);
  }
}

class _CommentItem extends StatelessWidget {
  const _CommentItem({
    required this.comment,
    required this.level,
    required this.collapsed,
    required this.onToggle,
    required this.onReply,
    required this.buildChild,
  });
  final Comment comment; // Comment
  final int level;
  final bool collapsed;
  final VoidCallback onToggle;
  final VoidCallback onReply;
  final Widget Function(dynamic) buildChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.author.name,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                icon: Icon(collapsed ? Icons.unfold_more : Icons.unfold_less),
                onPressed: onToggle,
              ),
            ],
          ),
          if (!collapsed) ...[
            Text(sanitizeText(comment.contentMarkdown)),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onReply,
                  icon: const Icon(Icons.reply_outlined),
                  label: const Text('Balas'),
                ),
              ],
            ),
            buildChild(comment),
          ],
        ],
      ),
    );
  }
}
