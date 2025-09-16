import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../providers/post_feed_provider.dart';
import '../widgets/category_chips.dart';
import '../widgets/post_card.dart';
import '../widgets/feed_skeleton.dart';
import '../../shared/utils/debouncer.dart';
import '../../shared/widgets/error_view.dart';
import '../widgets/trending_tags.dart';
import '../models/post.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 400);
  final _refreshController = RefreshController(initialRefresh: false);

  @override
  void dispose() {
    _searchCtrl.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(postFeedProvider);
    final pendingAsync = ref.watch(pendingActionsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            hintText: 'Cari diskusi...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          onChanged: (val) => _debouncer(
            () => ref.read(postFeedProvider.notifier).setQuery(val),
          ),
        ),
        actions: [
          // Sync indicator
          pendingAsync.maybeWhen(
            data: (count) => Stack(
              children: [
                // Const widget for better performance
                const IconButton(icon: Icon(Icons.sync), onPressed: null),
                if (count > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          // Const widgets for better performance
          const IconButton(icon: Icon(Icons.person), onPressed: null),
          const IconButton(icon: Icon(Icons.logout), onPressed: null),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/posts/new'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Tulis'),
      ),
      body: feedAsync.when(
        loading: () => const Skeleton(),
        error: (e, st) => ErrorView(
          message: 'Gagal memuat: $e',
          onRetry: () => ref.read(postFeedProvider.notifier).refresh(),
        ),
        data: (state) {
          // Show empty state when there are no posts
          if (state.posts.isEmpty) {
            return const _EmptyState();
          }

          if (state.initializing && state.posts.isEmpty) {
            return const Skeleton();
          }
          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: state.hasMore,
            header: const WaterDropHeader(),
            footer: const ClassicFooter(loadStyle: LoadStyle.ShowWhenLoading),
            onRefresh: () async {
              await ref.read(postFeedProvider.notifier).refresh();
              _refreshController.refreshCompleted();
              final s = ref.read(postFeedProvider).value;
              if (s != null && s.offline && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anda offline - menampilkan cache'),
                  ),
                );
              }
            },
            onLoading: () async {
              await ref.read(postFeedProvider.notifier).loadMore();
              _refreshController.loadComplete();
            },
            child: CustomScrollView(
              slivers: [
                // Offline banner
                SliverToBoxAdapter(
                  child: state.offline
                      ? Container(
                          width: double.infinity,
                          color: Theme.of(
                            context,
                          ).colorScheme.tertiaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            'Offline - perubahan akan disinkronkan saat online',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(child: CategoryChips()),
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                const SliverToBoxAdapter(child: TrendingTags()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Popular section
                const SliverToBoxAdapter(child: _PopularSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Feed list with optimized builder
                SliverList.builder(
                  itemCount: state.posts.length,
                  itemBuilder: (context, index) {
                    final p = state.posts[index];
                    // Const widget for better performance
                    return PostCard(post: p);
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 72)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Empty state widget for when there are no posts
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada post yang tersedia saat ini. Mulailah berbagi cerita pertama Anda!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // Navigate to create post
              GoRouter.of(context).go('/posts/new');
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Tulis Post Pertama'),
          ),
        ],
      ),
    );
  }
}

class _PopularSection extends ConsumerWidget {
  const _PopularSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(popularPostsProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                'Populer Minggu Ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final p = items[index];
                  return _PopularCard(post: p);
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: items.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.post});
  final Post post;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push('/posts/${post.id}'),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                post.excerpt ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.favorite, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${post.votes}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.mode_comment_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
