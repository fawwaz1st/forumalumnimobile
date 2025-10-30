import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/features/forum/data/models/post_model.dart';
import 'package:forum_alumni/features/forum/data/models/forum_user.dart';
import 'package:forum_alumni/features/forum/application/forum_controller.dart';
import 'package:forum_alumni/core/services/local_storage_service.dart';
import 'package:forum_alumni/core/services/connectivity_service.dart';

final offlinePostControllerProvider = StateNotifierProvider<OfflinePostController, AsyncValue<List<PostModel>>>((ref) {
  final forumNotifier = ref.read(forumNotifierProvider.notifier);
  final connectivityService = ref.read(connectivityServiceProvider);
  return OfflinePostController(forumNotifier, connectivityService);
});

class OfflinePostController extends StateNotifier<AsyncValue<List<PostModel>>> {
  OfflinePostController(this._forumNotifier, this._connectivityService) : super(const AsyncValue.loading()) {
    _loadPosts();
  }

  final ForumNotifier _forumNotifier;
  final ConnectivityService _connectivityService;

  Future<void> _loadPosts() async {
    try {
      if (_connectivityService.isConnected) {
        // Online: fetch from API and cache
        await _loadPostsOnline();
      } else {
        // Offline: load from cache
        await _loadPostsOffline();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _loadPostsOnline() async {
    try {
      // Use existing forum notifier to fetch posts
      await _forumNotifier.fetchInitial();
      
      // Get posts from the notifier state
      final forumState = _forumNotifier.debugState;
      if (forumState.isLoaded) {
        // Cache the posts for offline use
        await LocalStorageService.cachePosts(forumState.posts);
        state = AsyncValue.data(forumState.posts);
      } else {
        await _loadPostsOffline();
      }
      
    } catch (e) {
      // If online fails, try cache
      await _loadPostsOffline();
    }
  }

  Future<void> _loadPostsOffline() async {
    try {
      final cachedPosts = await LocalStorageService.getCachedPosts();
      
      if (cachedPosts != null && cachedPosts.isNotEmpty) {
        state = AsyncValue.data(cachedPosts);
      } else {
        state = const AsyncValue.error('No cached posts available offline', StackTrace.empty);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error('Failed to load cached posts: $e', stackTrace);
    }
  }

  Future<void> refreshPosts() async {
    state = const AsyncValue.loading();
    await _loadPosts();
  }

  Future<void> createPostOffline(String content, String? mediaUrl, String? mediaType) async {
    if (!_connectivityService.isConnected) {
      // Create pending action for when back online
      await LocalStorageService.addPendingAction({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'create_post',
        'content': content,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Create temporary post for immediate UI feedback
      final tempPost = PostModel(
        id: -DateTime.now().millisecondsSinceEpoch, // Negative ID for temp posts
        content: content,
        author: const ForumUser(id: 0, name: 'You', avatarUrl: null), // Placeholder
        createdAt: DateTime.now(),
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        isLiked: false,
        likesCount: 0,
        commentsCount: 0,
      );

      // Add to current state
      state.whenData((posts) {
        final updatedPosts = [tempPost, ...posts];
        state = AsyncValue.data(updatedPosts);
        
        // Cache updated posts
        LocalStorageService.cachePosts(updatedPosts);
      });
    } else {
      // Online: use regular forum notifier
      // TODO: Add createPost method to ForumNotifier
      await refreshPosts();
    }
  }

  Future<void> toggleLikeOffline(int postId) async {
    if (!_connectivityService.isConnected) {
      // Add pending action
      await LocalStorageService.addPendingAction({
        'id': '${postId}_like_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'like_post',
        'postId': postId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update UI immediately
      state.whenData((posts) {
        final updatedPosts = posts.map((post) {
          if (post.id == postId) {
            return PostModel(
              id: post.id,
              content: post.content,
              author: post.author,
              createdAt: post.createdAt,
              mediaUrl: post.mediaUrl,
              mediaType: post.mediaType,
              isLiked: !post.isLiked,
              likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
              commentsCount: post.commentsCount,
            );
          }
          return post;
        }).toList();

        state = AsyncValue.data(updatedPosts);
        LocalStorageService.cachePosts(updatedPosts);
      });
    } else {
      // Online: use regular forum notifier
      // TODO: Add toggleLike method to ForumNotifier
      await refreshPosts();
    }
  }

  Future<void> deletePostOffline(int postId) async {
    if (!_connectivityService.isConnected) {
      // Add pending action
      await LocalStorageService.addPendingAction({
        'id': '${postId}_delete_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'delete_post',
        'postId': postId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      // Online: use regular forum notifier
      // TODO: Add deletePost method to ForumNotifier
    }

    // Remove from current state immediately
    state.whenData((posts) {
      final updatedPosts = posts.where((post) => post.id != postId).toList();
      state = AsyncValue.data(updatedPosts);
      LocalStorageService.cachePosts(updatedPosts);
    });
  }

  Future<Map<String, int>> getCacheInfo() async {
    return await LocalStorageService.getCacheInfo();
  }

  Future<void> clearCache() async {
    await LocalStorageService.clearAllCache();
    if (!_connectivityService.isConnected) {
      state = const AsyncValue.error('No cached data available offline', StackTrace.empty);
    } else {
      await refreshPosts();
    }
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    return await LocalStorageService.getPendingActions();
  }
}
