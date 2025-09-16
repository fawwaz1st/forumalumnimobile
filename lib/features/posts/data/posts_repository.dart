import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' as f;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_config.dart';
import 'posts_remote.dart';
import '../../../services/api/post_api.dart';
import '../../../services/api/mock_api_service.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/category.dart';
import '../models/tag.dart';

class PostsRepository {
  PostsRepository(this._api);
  final IPostsRemote _api;

  // Cache boxes (lazy)
  Future<Box<String>> get _cacheBox async => Hive.isBoxOpen('posts_cache')
      ? Hive.box<String>('posts_cache')
      : await Hive.openBox<String>('posts_cache');
  Future<Box<String>> get _queueBox async => Hive.isBoxOpen('posts_queue')
      ? Hive.box<String>('posts_queue')
      : await Hive.openBox<String>('posts_queue');
  Future<Box<String>> get _draftBox async => Hive.isBoxOpen('post_drafts')
      ? Hive.box<String>('post_drafts')
      : await Hive.openBox<String>('post_drafts');

  // --- Network ---
  Future<List<Category>> listCategories() => _api.listCategories();
  Future<List<Tag>> listTags() => _api.listTags();

  Future<List<Post>> fetchPosts({required int page, required int limit, String? query, String? categoryId}) async {
    final posts = await _api.fetchPosts(page: page, limit: limit, query: query, categoryId: categoryId);
    if (page == 1 && (query == null || query.isEmpty) && (categoryId == null || categoryId == 'all')) {
      // Cache only main feed (no filters)
      await cacheFeed(posts);
    }
    return posts;
  }

  Future<Post> getPost(String id) => _api.getPost(id);
  Future<Post> votePost({required String postId, required int vote}) => _api.votePost(postId: postId, vote: vote);
  Future<Post> bookmarkPost({required String postId, required bool bookmarked}) => _api.bookmarkPost(postId: postId, bookmarked: bookmarked);
  Future<List<Comment>> getComments(String postId) => _api.getComments(postId);
  Future<Comment> addReply({required String postId, String? parentId, required String contentMarkdown}) => _api.addReply(postId: postId, parentId: parentId, contentMarkdown: contentMarkdown);
  Future<Post> createPost({required String title, required String contentMarkdown, String? categoryId, List<String> tagIds = const []}) =>
      _api.createPost(title: title, contentMarkdown: contentMarkdown, categoryId: categoryId, tagIds: tagIds);
  Future<Post> updatePost({required String id, String? title, String? contentMarkdown, String? categoryId, List<String>? tagIds}) =>
      _api.updatePost(id: id, title: title, contentMarkdown: contentMarkdown, categoryId: categoryId, tagIds: tagIds);

  // --- Cache ---
  Future<void> cacheFeed(List<Post> posts) async {
    final box = await _cacheBox;
    final limited = posts.take(50).toList();
    await box.put('feed_cache_v1', Post.listToJsonString(limited));
  }

  Future<List<Post>> readCachedFeed() async {
    final box = await _cacheBox;
    final str = box.get('feed_cache_v1');
    if (str == null) return [];
    try {
      // Parse on background isolate to avoid jank
      return f.compute(_parsePostsFromCache, str);
    } catch (_) {
      return [];
    }
  }

  // --- Drafts ---
  Future<void> saveDraft(String key, Map<String, dynamic> draft) async {
    final box = await _draftBox;
    await box.put(key, jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> readDraft(String key) async {
    final box = await _draftBox;
    final str = box.get(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteDraft(String key) async {
    final box = await _draftBox;
    await box.delete(key);
  }

  Future<List<Map<String, dynamic>>> listAllDrafts() async {
    final box = await _draftBox;
    final List<Map<String, dynamic>> drafts = [];
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is String) {
        try {
          final obj = jsonDecode(v) as Map<String, dynamic>;
          drafts.add({'key': k.toString(), ...obj});
        } catch (_) {}
      }
    }
    // sort by updatedAt if exists
    drafts.sort((a, b) => (b['updatedAt'] ?? 0).compareTo(a['updatedAt'] ?? 0));
    return drafts;
  }

  // --- Queue (simple) ---
  Future<void> enqueueAction(Map<String, dynamic> action) async {
    final box = await _queueBox;
    final list = (jsonDecode(box.get('queue_v1') ?? '[]') as List).cast<Map<String, dynamic>>();
    list.add(action);
    await box.put('queue_v1', jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> readQueue() async {
    final box = await _queueBox;
    return (jsonDecode(box.get('queue_v1') ?? '[]') as List).cast<Map<String, dynamic>>();
  }

  Future<void> clearQueue() async {
    final box = await _queueBox;
    await box.put('queue_v1', '[]');
  }

  Future<void> processQueue() async {
    final list = await readQueue();
    if (list.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final a in list) {
      try {
        switch (a['type'] as String) {
          case 'vote':
            await votePost(postId: a['postId'] as String, vote: a['vote'] as int);
            break;
          case 'bookmark':
            await bookmarkPost(postId: a['postId'] as String, bookmarked: a['bookmarked'] as bool);
            break;
          case 'create':
            await createPost(
              title: a['title'] as String,
              contentMarkdown: a['contentMarkdown'] as String,
              categoryId: a['categoryId'] as String?,
              tagIds: (a['tagIds'] as List?)?.cast<String>() ?? const [],
            );
            break;
          case 'update':
            await updatePost(
              id: a['id'] as String,
              title: a['title'] as String?,
              contentMarkdown: a['contentMarkdown'] as String?,
              categoryId: a['categoryId'] as String?,
              tagIds: (a['tagIds'] as List?)?.cast<String>(),
            );
            break;
          default:
            break;
        }
      } catch (_) {
        remaining.add(a); // keep if fail
      }
    }
    final box = await _queueBox;
    await box.put('queue_v1', jsonEncode(remaining));
  }

  // --- Upload (mock) ---
  Future<String> uploadImageBytes(Uint8List data, {String? fileName}) async {
    // Simulasi upload: abaikan data dan kembalikan URL picsum
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return 'https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/1200/800';
  }
}

final postsRemoteProvider = Provider<IPostsRemote>((ref) {
  if (AppConfig.useMock) {
    return ref.read(mockApiServiceProvider);
  }
  return ref.read(postApiProvider);
});

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  final api = ref.read(postsRemoteProvider);
  return PostsRepository(api);
});

// Helper function used by f.compute to parse cached posts on a background isolate
List<Post> _parsePostsFromCache(String str) {
  try {
    return Post.listFromJsonString(str);
  } catch (_) {
    return <Post>[];
  }
}
