import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../bookmarks/providers/bookmarks_provider.dart';

class BookmarksView extends ConsumerWidget {
  const BookmarksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(bookmarksListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmark'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(bookmarksListProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Gagal memuat: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Belum ada bookmark.'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = list[index];
                  return ListTile(
                    title: Text(p.title),
                    subtitle: Text(p.excerpt ?? p.contentMarkdown, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => context.go('/posts/${p.id}'),
                  );
                },
              ),
      ),
    );
  }
}
