import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../models/post.dart';
import '../providers/post_feed_provider.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> with AutomaticKeepAliveClientMixin {
  bool _animating = false;

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}j';
    return '${diff.inDays}h';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = widget.post;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 1.2,
      shadowColor: cs.shadow.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/posts/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: p.author.avatar != null
                        ? CachedNetworkImageProvider(p.author.avatar!)
                        : null,
                    child: p.author.avatar == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.author.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(p.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Title
              Hero(
                tag: 'post_title_${p.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    p.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (p.excerpt != null && p.excerpt!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  p.excerpt!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Optional image
              if ((p.imageUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: p.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    filterQuality: FilterQuality.low,
                    memCacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(),
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: cs.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Tags/Category
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (p.category != null)
                    _LabelChip(
                      label: p.category!.name,
                      color: Color(p.category!.color),
                      icon: Icons.folder_open,
                    ),
                  for (final t in p.tags)
                    _LabelChip(
                      label: t.name,
                      color: Color(t.color),
                      icon: Icons.tag,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Actions row
              Row(
                children: [
                  // Like
                  IconButton(
                    icon: Icon(
                      p.userVote == 1 ? Icons.favorite : Icons.favorite_border,
                    ),
                    color: p.userVote == 1 ? cs.primary : cs.onSurfaceVariant,
                    onPressed: () async {
                      setState(() => _animating = true);
                      HapticFeedback.lightImpact();
                      final newVote = p.userVote == 1 ? 0 : 1;
                      await ref
                          .read(postFeedProvider.notifier)
                          .vote(postId: p.id, vote: newVote);
                      if (mounted) setState(() => _animating = false);
                    },
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: _animating ? 1.15 : 1.0,
                    child: Text(
                      '${p.votes}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Comment count
                  const Icon(Icons.mode_comment_outlined, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${p.commentsCount}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      final url = 'https://forum.example.com/posts/${p.id}';
                      Share.share('Lihat diskusi: $url');
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      p.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(postFeedProvider.notifier)
                          .bookmark(postId: p.id, bookmarked: !p.bookmarked);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = color.withOpacity(0.12);
    final fg = color;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}
