import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forum_alumni/features/auth/application/auth_controller.dart';
import 'package:forum_alumni/features/forum/application/forum_controller.dart';
import 'package:forum_alumni/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:forum_alumni/features/forum/presentation/create_post_screen.dart';
import 'package:forum_alumni/features/forum/presentation/post_detail_screen.dart';
import 'package:forum_alumni/features/profile/presentation/profile_screen.dart';
import 'package:forum_alumni/features/forum/presentation/widgets/post_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = 'home';
  static const String routePath = '/';

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentOffset = _scrollController.offset;
    if (currentOffset >= maxScroll - 200) {
      ref.read(forumNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final forumState = ref.watch(forumNotifierProvider);

    ref.listen<ForumState>(forumNotifierProvider, (previous, next) {
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
        title: const Text('Forum Alumni'),
        actions: [
          IconButton(
            tooltip: 'Buat postingan',
            onPressed: () => context.pushNamed(CreatePostScreen.routeName),
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.pushNamed(ProfileScreen.routeName);
                  break;
                case 'admin':
                  context.pushNamed(AdminDashboardScreen.routeName);
                  break;
                case 'logout':
                  ref.read(authNotifierProvider.notifier).logout();
                  break;
              }
            },
            itemBuilder: (context) {
              final user = authState.user;
              return [
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profil Saya'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (user?.role == 'admin')
                  const PopupMenuItem(
                    value: 'admin',
                    child: ListTile(
                      leading: Icon(Icons.admin_panel_settings),
                      title: Text('Dashboard Admin'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Keluar', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(CreatePostScreen.routeName),
        icon: const Icon(Icons.create),
        label: const Text('Buat Postingan'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(forumNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (authState.user != null)
                      _ProfileHeader(
                        userName: authState.user!.name,
                        email: authState.user!.email,
                        role: authState.user!.role,
                        avatarUrl: authState.user!.avatarUrl,
                      ),
                    if (authState.user != null) const SizedBox(height: 16),
                    Text(
                      'Terbaru',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (forumState.isLoading && forumState.posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (forumState.posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = forumState.posts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          post: post,
                          onTap: () => context.pushNamed(
                            PostDetailScreen.routeName,
                            pathParameters: {'id': post.id.toString()},
                          ),
                          onLikeTap: () => ref
                              .read(forumNotifierProvider.notifier)
                              .toggleLike(post),
                          onCommentTap: () => context.pushNamed(
                            PostDetailScreen.routeName,
                            pathParameters: {'id': post.id.toString()},
                          ),
                        ),
                      );
                    },
                    childCount: forumState.posts.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Visibility(
                visible: forumState.isLoadingMore,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.userName,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  final String userName;
  final String email;
  final String role;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?')
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(role.toUpperCase()),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.forum_outlined, size: 72, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Belum ada postingan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Jadilah yang pertama untuk memulai diskusi!'
          '\nTarik ke bawah untuk memuat ulang.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
