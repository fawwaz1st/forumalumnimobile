import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/post_feed_provider.dart';
import '../models/category.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final feed = ref.watch(postFeedProvider).value;
    final selected = feed?.categoryId ?? 'all';

    return SizedBox(
      height: 42,
      child: categories.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, _) => Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Gagal memuat kategori'),
          ],
        ),
        data: (list) {
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final Category c = list[index];
              final bool isSelected = c.id == selected;
              return ChoiceChip(
                label: Text(c.name),
                selected: isSelected,
                onSelected: (v) {
                  ref.read(postFeedProvider.notifier).setCategory(c.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
