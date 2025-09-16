import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../auth/providers/auth_controller.dart';
import 'package:go_router/go_router.dart';
import '../../posts/providers/post_feed_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final feed = ref.watch(postFeedProvider).valueOrNull;
    final myPosts =
        feed?.posts
            .where((p) => user != null && p.author.id == user.id)
            .length ??
        0;
    final myComments = 0; // mock, bisa diisi dari API nyata
    final reputation =
        (feed?.posts
            .where((p) => user != null && p.author.id == user.id)
            .fold<int>(0, (a, b) => a + b.votes) ??
        0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Belum masuk.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Modern profile header with better layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular avatar with border
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            (user.avatar != null && user.avatar!.isNotEmpty)
                            ? NetworkImage(user.avatar!)
                            : null,
                        child: (user.avatar == null || user.avatar!.isEmpty)
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                          const SizedBox(height: 8),
                          // Joined date
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Bergabung ${_formatDate(user.joinDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bio section
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(user.bio!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Stats section with modern cards
                const Text(
                  'Statistik',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Posting',
                        value: myPosts,
                        icon: Icons.article_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Komentar',
                        value: myComments,
                        icon: Icons.comment_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Reputasi',
                        value: reputation,
                        icon: Icons.star_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Menu items
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: const Text('Posting Saya'),
                        subtitle: const Text('Terbit & Draft'),
                        onTap: () => context.push('/profile/myposts'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.bookmark_outline),
                        title: const Text('Bookmark'),
                        onTap: () => context.push('/profile/bookmarks'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Achievements section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pencapaian',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _AchievementChip(
                              icon: Icons.verified,
                              label: 'Akun Terverifikasi',
                              color: Colors.green,
                            ),
                            _AchievementChip(
                              icon: Icons.star,
                              label: 'Kontributor Aktif',
                              color: Colors.amber,
                            ),
                            _AchievementChip(
                              icon: Icons.rocket_launch,
                              label: 'Pendatang Baru',
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'baru saja';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    } else {
      return '${(difference.inDays / 365).floor()} tahun yang lalu';
    }
  }
}

// Modern stat card widget
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Achievement chip widget
class _AchievementChip extends StatelessWidget {
  const _AchievementChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
