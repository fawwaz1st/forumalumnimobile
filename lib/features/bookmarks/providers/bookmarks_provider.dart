import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../posts/models/post.dart';

class BookmarksRepository {
  Future<Box<String>> get _box async => Hive.isBoxOpen('bookmarks_v1')
      ? Hive.box<String>('bookmarks_v1')
      : await Hive.openBox<String>('bookmarks_v1');

  Future<void> setBookmark(Post post, bool bookmarked) async {
    final box = await _box;
    if (bookmarked) {
      await box.put(post.id, jsonEncode(post.toJson()));
    } else {
      await box.delete(post.id);
    }
  }

  Future<List<Post>> listAll() async {
    final box = await _box;
    final list = <Post>[];
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is String) {
        try {
          final map = jsonDecode(v) as Map<String, dynamic>;
          list.add(Post.fromJson(map));
        } catch (_) {}
      }
    }
    return list;
  }
}

final bookmarksRepositoryProvider = Provider<BookmarksRepository>((ref) => BookmarksRepository());

final bookmarksListProvider = FutureProvider<List<Post>>((ref) async {
  return ref.read(bookmarksRepositoryProvider).listAll();
});
