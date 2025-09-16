import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../data/posts_repository.dart';
import '../models/post.dart';
import '../models/category.dart' as model;
import '../models/tag.dart';
import '../models/comment.dart';
import '../../bookmarks/providers/bookmarks_provider.dart';

class PostFeedState {
  final List<Post> posts;
  final int page;
  final bool hasMore;
  final String query;
  final String categoryId;
  final bool isRefreshing;
  final bool initializing;
  final bool offline;

  const PostFeedState({
    this.posts = const [],
    this.page = 1,
    this.hasMore = true,
    this.query = '',
    this.categoryId = 'all',
    this.isRefreshing = false,
    this.initializing = true,
    this.offline = false,
  });

  PostFeedState copyWith({
    List<Post>? posts,
    int? page,
    bool? hasMore,
    String? query,
    String? categoryId,
    bool? isRefreshing,
    bool? initializing,
    bool? offline,
  }) {
    return PostFeedState(
      posts: posts ?? this.posts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      initializing: initializing ?? this.initializing,
      offline: offline ?? this.offline,
    );
  }
}

final postsRepositoryProviderRef = postsRepositoryProvider; // re-export

final categoriesProvider = FutureProvider<List<model.Category>>((ref) async {
  final repo = ref.read(postsRepositoryProvider);
  return repo.listCategories();
});

final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final repo = ref.read(postsRepositoryProvider);
  return repo.listTags();
});

class PostFeedNotifier extends AsyncNotifier<PostFeedState> {
  PostsRepository get _repo => ref.read(postsRepositoryProvider);

  @override
  Future<PostFeedState> build() async {
    // Only load cached if we're using mock, otherwise start fresh
    final cached = AppConfig.useMock ? await _repo.readCachedFeed() : <Post>[];
    final initial = PostFeedState(posts: cached, initializing: true);
    // Process pending actions in background (offline queue)  
    unawaited(_repo.processQueue());
    // Kick off initial network load (page 1)
    unawaited(_loadFirstPage(initial.query, initial.categoryId));
    return initial;
  }

  Future<void> _loadFirstPage(String query, String categoryId) async {
    state = const AsyncLoading();
    try {
      final items = await _repo.fetchPosts(
        page: 1,
        limit: 10,
        query: query,
        categoryId: categoryId,
      );
      // Debug logging to verify data source
      if (kDebugMode) {
        print('Feed loaded: ${items.length} posts from ${AppConfig.useMock ? 'MOCK' : 'API'} service');
      }
      state = AsyncData(
        PostFeedState(
          posts: items,
          page: 1,
          hasMore: items.length >= 10,
          query: query,
          categoryId: categoryId,
          initializing: false,
        ),
      );
    } catch (e) {
      // When not using mock and API fails, show empty state instead of cache
      if (AppConfig.useMock) {
        final cached = await _repo.readCachedFeed();
        state = AsyncData(
          PostFeedState(
            posts: cached,
            page: 1,
            hasMore: cached.length >= 10,
            query: query,
            categoryId: categoryId,
            initializing: false,
            offline: true,
          ),
        );
      } else {
        // Production mode - show empty state when API fails
        state = AsyncData(
          PostFeedState(
            posts: <Post>[],
            page: 1,
            hasMore: false,
            query: query,
            categoryId: categoryId,
            initializing: false,
            offline: true,
          ),
        );
      }
    }
  }

  Future<void> refresh() async {
    final curr = state.value ?? const PostFeedState();
    state = AsyncData(curr.copyWith(isRefreshing: true));
    try {
      final items = await _repo.fetchPosts(
        page: 1,
        limit: 10,
        query: curr.query,
        categoryId: curr.categoryId,
      );
      state = AsyncData(
        curr.copyWith(
          posts: items,
          page: 1,
          hasMore: items.length >= 10,
          isRefreshing: false,
          initializing: false,
          offline: false,
        ),
      );
    } catch (e) {
      // When not using mock and refresh fails, don't fallback to cached dummy data
      if (AppConfig.useMock) {
        state = AsyncData(curr.copyWith(isRefreshing: false, offline: true));
      } else {
        // Production mode - show empty if refresh fails
        state = AsyncData(curr.copyWith(
          posts: <Post>[],
          isRefreshing: false,
          offline: true,
          hasMore: false,
        ));
      }
    }
  }

  Future<void> loadMore() async {
    final curr = state.value;
    if (curr == null || !curr.hasMore) return;
    try {
      final nextPage = curr.page + 1;
      final items = await _repo.fetchPosts(
        page: nextPage,
        limit: 10,
        query: curr.query,
        categoryId: curr.categoryId,
      );
      state = AsyncData(
        curr.copyWith(
          posts: [...curr.posts, ...items],
          page: nextPage,
          hasMore: items.length >= 10,
          initializing: false,
        ),
      );
    } catch (e) {
      state = AsyncData(curr.copyWith(offline: true));
    }
  }

  Future<void> setCategory(String categoryId) async {
    final curr = state.value ?? const PostFeedState();
    state = AsyncData(curr.copyWith(categoryId: categoryId));
    await _loadFirstPage(curr.query, categoryId);
  }

  Future<void> setQuery(String query) async {
    final curr = state.value ?? const PostFeedState();
    state = AsyncData(curr.copyWith(query: query));
    await _loadFirstPage(query, curr.categoryId);
  }

  // Optimistic updates
  Future<void> vote({required String postId, required int vote}) async {
    final curr = state.value;
    if (curr == null) return;
    final idx = curr.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = curr.posts[idx];
    final prev = post;
    int newVotes = post.votes + (vote == 1 ? 1 : (vote == -1 ? -1 : 0));
    final optimistic = post.copyWith(votes: newVotes, userVote: vote);
    final newList = [...curr.posts];
    newList[idx] = optimistic;
    state = AsyncData(curr.copyWith(posts: newList));
    try {
      final server = await _repo.votePost(postId: postId, vote: vote);
      final list2 = [...state.value!.posts];
      final idx2 = list2.indexWhere((p) => p.id == postId);
      if (idx2 != -1) list2[idx2] = server;
      state = AsyncData(state.value!.copyWith(posts: list2, offline: false));
    } catch (_) {
      // revert and enqueue
      final list2 = [...state.value!.posts];
      final idx2 = list2.indexWhere((p) => p.id == postId);
      if (idx2 != -1) list2[idx2] = prev;
      state = AsyncData(state.value!.copyWith(posts: list2, offline: true));
      await _repo.enqueueAction({
        'type': 'vote',
        'postId': postId,
        'vote': vote,
      });
    }
  }

  Future<void> bookmark({
    required String postId,
    required bool bookmarked,
  }) async {
    final curr = state.value;
    if (curr == null) return;
    final idx = curr.posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final prev = curr.posts[idx];
    final optimistic = prev.copyWith(bookmarked: bookmarked);
    final newList = [...curr.posts];
    newList[idx] = optimistic;
    state = AsyncData(curr.copyWith(posts: newList));
    // Persist locally for offline access
    try {
      await ref
          .read(bookmarksRepositoryProvider)
          .setBookmark(optimistic, bookmarked);
    } catch (_) {}
    try {
      final server = await _repo.bookmarkPost(
        postId: postId,
        bookmarked: bookmarked,
      );
      final list2 = [...state.value!.posts];
      final idx2 = list2.indexWhere((p) => p.id == postId);
      if (idx2 != -1) list2[idx2] = server;
      state = AsyncData(state.value!.copyWith(posts: list2, offline: false));
      try {
        await ref
            .read(bookmarksRepositoryProvider)
            .setBookmark(server, bookmarked);
      } catch (_) {}
    } catch (_) {
      // keep optimistic but mark offline and enqueue
      state = AsyncData(state.value!.copyWith(offline: true));
      await _repo.enqueueAction({
        'type': 'bookmark',
        'postId': postId,
        'bookmarked': bookmarked,
      });
    }
  }
}

final postFeedProvider = AsyncNotifierProvider<PostFeedNotifier, PostFeedState>(
  PostFeedNotifier.new,
);

final postByIdProvider = FutureProvider.family<Post, String>((ref, id) async {
  final repo = ref.read(postsRepositoryProvider);
  return repo.getPost(id);
});

final commentsProvider = FutureProvider.family
    .autoDispose<List<Comment>, String>((ref, postId) async {
      final repo = ref.read(postsRepositoryProvider);
      return repo.getComments(postId);
    });

final pendingActionsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(postsRepositoryProvider);
  final q = await repo.readQueue();
  return q.length;
});

/// Popular posts this week provider (simple client-side sort by votes)
final popularPostsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.read(postsRepositoryProvider);
  try {
    final items = await repo.fetchPosts(
      page: 1,
      limit: 20,
      query: null,
      categoryId: 'all',
    );
    final sorted = [...items]..sort((a, b) => b.votes.compareTo(a.votes));
    return sorted.take(5).toList();
  } catch (_) {
    // When not using mock, return empty instead of cached dummy data
    if (AppConfig.useMock) {
      final cached = await repo.readCachedFeed();
      final sorted = [...cached]..sort((a, b) => b.votes.compareTo(a.votes));
      return sorted.take(5).toList();
    } else {
      return <Post>[];
    }
  }
});
