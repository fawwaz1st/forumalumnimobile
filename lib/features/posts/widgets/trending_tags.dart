import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/post_feed_provider.dart';
import '../models/tag.dart';

class TrendingTags extends ConsumerWidget {
  const TrendingTags({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    if (tagsAsync.isLoading) {
      return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return tagsAsync.maybeWhen(
      error: (e, _) => const SizedBox.shrink(),
      data: (tags) => SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final Tag t = tags[index];
            return ActionChip(
              label: Text('#${t.name}'),
              avatar: const Icon(Icons.trending_up, size: 16),
              onPressed: () => ref.read(postFeedProvider.notifier).setQuery(t.name),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: tags.length,
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
