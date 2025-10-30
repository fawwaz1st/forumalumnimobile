import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forum_alumni/features/admin/application/admin_controller.dart';
import 'package:forum_alumni/features/auth/application/auth_controller.dart';
import 'package:forum_alumni/features/forum/application/post_detail_controller.dart';
import 'package:forum_alumni/features/forum/data/models/post_comment.dart';
import 'package:forum_alumni/features/forum/presentation/widgets/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  static const String routeName = 'post-detail';
  static const String routePath = 'posts/:id';

  final int postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postDetailNotifierProvider(widget.postId));
    final authState = ref.watch(authNotifierProvider);
    final notifier = ref.read(postDetailNotifierProvider(widget.postId).notifier);

    ref.listen<PostDetailState>(postDetailNotifierProvider(widget.postId), (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null && 
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.post?.author.name ?? 'Detail Postingan'),
        actions: [
          if (authState.user?.role == 'admin' && state.post != null)
            PopupMenuButton<String>(
              tooltip: 'Aksi Admin',
              onSelected: (value) {
                switch (value) {
                  case 'delete_post':
                    _showDeletePostDialog(context, state.post!);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_post',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Hapus Postingan'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: state.isLoading ? null : notifier.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.post == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PostDetailStatus.error && state.post == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Gagal memuat postingan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: notifier.load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final post = state.post;
          if (post == null) {
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PostCard(
                        post: post,
                        onLikeTap: () => notifier.toggleLike(),
                        onCommentTap: () {},
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Komentar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (post.comments.isEmpty)
                        const _EmptyComments()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: post.comments.length,
                          itemBuilder: (context, index) {
                            final comment = post.comments[index];
                            return _CommentTile(
                              comment: comment,
                              onReply: (content) => notifier.addComment(
                                content: content,
                                parentId: comment.id,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Tulis komentar...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: state.isCommentSubmitting
                                ? null
                                : () async {
                                    final text = _commentController.text.trim();
                                    if (text.isEmpty) return;
                                    await notifier.addComment(content: text);
                                    if (!mounted) return;
                                    _commentController.clear();
                                  },
                            icon: state.isCommentSubmitting
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Kirim'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeletePostDialog(BuildContext context, post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Postingan'),
        content: const Text('Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(adminNotifierProvider.notifier).deletePost(post);
              context.pop(); // Go back to previous screen
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Belum ada komentar',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Jadilah yang pertama memberikan komentar!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
  });

  final PostComment comment;
  final Future<void> Function(String content) onReply;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplyField = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                child: Text(
                  widget.comment.author.name.isNotEmpty
                      ? widget.comment.author.name[0].toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comment.author.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(widget.comment.content),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          widget.comment.createdAt.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showReplyField = !_showReplyField;
                            });
                          },
                          child: const Text('Balas'),
                        ),
                      ],
                    ),
                    if (widget.comment.replies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.comment.replies
                              .map(
                                (reply) => Padding(
                                  padding: const EdgeInsets.only(left: 24, bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        child: Text(
                                          reply.author.name.isNotEmpty
                                              ? reply.author.name[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reply.author.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(reply.content),
                                            const SizedBox(height: 4),
                                            Text(
                                              reply.createdAt.toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (_showReplyField)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _replyController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Tulis balasan...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () async {
                                  final text = _replyController.text.trim();
                                  if (text.isEmpty) return;
                                  await widget.onReply(text);
                                  if (!mounted) return;
                                  _replyController.clear();
                                  setState(() {
                                    _showReplyField = false;
                                  });
                                },
                                child: const Text('Kirim'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
