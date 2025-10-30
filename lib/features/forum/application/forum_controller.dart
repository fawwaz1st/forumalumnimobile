import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/features/forum/data/forum_repository.dart';
import 'package:forum_alumni/features/forum/data/models/post_model.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository();
});

final forumNotifierProvider =
    StateNotifierProvider<ForumNotifier, ForumState>((ref) {
  final repository = ref.watch(forumRepositoryProvider);
  return ForumNotifier(repository);
});

enum ForumStatus { initial, loading, loaded, error }

class ForumState extends Equatable {
  const ForumState({
    this.status = ForumStatus.initial,
    this.posts = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isCreating = false,
    this.errorMessage,
  });

  final ForumStatus status;
  final List<PostModel> posts;
  final int currentPage;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isCreating;
  final String? errorMessage;

  bool get isLoading => status == ForumStatus.loading;
  bool get isInitial => status == ForumStatus.initial;
  bool get isLoaded => status == ForumStatus.loaded;

  ForumState copyWith({
    ForumStatus? status,
    List<PostModel>? posts,
    int? currentPage,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isCreating,
    String? errorMessage,
  }) {
    return ForumState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        currentPage,
        hasMore,
        isRefreshing,
        isLoadingMore,
        isCreating,
        errorMessage,
      ];
}

class ForumNotifier extends StateNotifier<ForumState> {
  ForumNotifier(this._repository) : super(const ForumState()) {
    unawaited(fetchInitial());
  }

  final ForumRepository _repository;

  Future<void> fetchInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      status: ForumStatus.loading,
      errorMessage: null,
    );

    try {
      final pagination = await _repository.fetchPosts(page: 1);
      state = state.copyWith(
        status: ForumStatus.loaded,
        posts: pagination.posts,
        currentPage: 1,
        hasMore: pagination.hasMore,
        errorMessage: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        status: ForumStatus.error,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        status: ForumStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing || state.isLoading) return;
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    try {
      final pagination = await _repository.fetchPosts(page: 1);
      state = state.copyWith(
        status: ForumStatus.loaded,
        posts: pagination.posts,
        currentPage: 1,
        hasMore: pagination.hasMore,
        isRefreshing: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading || state.isRefreshing) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final nextPage = state.currentPage + 1;
      final pagination = await _repository.fetchPosts(page: nextPage);
      final updatedPosts = List<PostModel>.from(state.posts)
        ..addAll(pagination.posts);

      state = state.copyWith(
        posts: updatedPosts,
        currentPage: nextPage,
        hasMore: pagination.hasMore,
        isLoadingMore: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> toggleLike(PostModel post) async {
    final index = state.posts.indexWhere((element) => element.id == post.id);
    if (index == -1) return;

    final optimistic = post.copyWith(
      isLiked: !post.isLiked,
      likesCount: post.likesCount + (post.isLiked ? -1 : 1),
    );

    final updatedPosts = List<PostModel>.from(state.posts)
      ..[index] = optimistic;

    state = state.copyWith(posts: updatedPosts);

    try {
      final refreshedPost = await _repository.toggleLike(post.id);
      final nextPosts = List<PostModel>.from(state.posts)
        ..[index] = refreshedPost;
      state = state.copyWith(posts: nextPosts);
    } on DioException catch (_) {
      state = state.copyWith(posts: state.posts);
    } catch (_) {
      state = state.copyWith(posts: state.posts);
    }
  }

  Future<void> addComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    await _repository.addComment(
      postId: postId,
      content: content,
      parentId: parentId,
    );
    await refresh();
  }

  Future<PostModel?> createPost({
    required String content,
    String? mediaPath,
    String? mediaType,
    List<int>? mediaBytes,
    String? mediaFilename,
  }) async {
    state = state.copyWith(isCreating: true, errorMessage: null);
    try {
      final post = await _repository.createPost(
        content: content,
        mediaPath: mediaPath,
        mediaType: mediaType,
        mediaBytes: mediaBytes,
        mediaFilename: mediaFilename,
      );
      final updatedPosts = [post, ...state.posts];
      state = state.copyWith(
        posts: updatedPosts,
        status: ForumStatus.loaded,
        currentPage: state.currentPage == 0 ? 1 : state.currentPage,
        isCreating: false,
      );
      return post;
    } on DioException catch (error) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: _mapError(error),
      );
      return null;
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: error.toString(),
      );
      return null;
    }
  }

  String _mapError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> data = error.response!.data as Map<String, dynamic>;
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return 'Permintaan gagal (${error.response?.statusCode ?? ''}).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan tidak diketahui.';
    }
  }
}
