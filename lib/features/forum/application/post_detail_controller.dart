import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/features/forum/application/forum_controller.dart'
    show forumRepositoryProvider;
import 'package:forum_alumni/features/forum/data/forum_repository.dart';
import 'package:forum_alumni/features/forum/data/models/post_model.dart';

final postDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<PostDetailNotifier, PostDetailState, int>((ref, postId) {
  final repository = ref.watch(forumRepositoryProvider);
  return PostDetailNotifier(repository, postId);
});

enum PostDetailStatus { initial, loading, loaded, error }

class PostDetailState extends Equatable {
  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.errorMessage,
    this.isCommentSubmitting = false,
  });

  final PostDetailStatus status;
  final PostModel? post;
  final String? errorMessage;
  final bool isCommentSubmitting;

  bool get isLoading => status == PostDetailStatus.loading;
  bool get isLoaded => status == PostDetailStatus.loaded;

  PostDetailState copyWith({
    PostDetailStatus? status,
    PostModel? post,
    String? errorMessage,
    bool? isCommentSubmitting,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      errorMessage: errorMessage,
      isCommentSubmitting: isCommentSubmitting ?? this.isCommentSubmitting,
    );
  }

  @override
  List<Object?> get props => [status, post, errorMessage, isCommentSubmitting];
}

class PostDetailNotifier extends StateNotifier<PostDetailState> {
  PostDetailNotifier(this._repository, this._postId)
      : super(const PostDetailState()) {
    unawaited(load());
  }

  final ForumRepository _repository;
  final int _postId;

  Future<void> load() async {
    state = state.copyWith(status: PostDetailStatus.loading, errorMessage: null);
    try {
      final post = await _repository.fetchPostDetail(_postId);
      state = state.copyWith(
        status: PostDetailStatus.loaded,
        post: post,
        errorMessage: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        status: PostDetailStatus.error,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        status: PostDetailStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> toggleLike() async {
    final currentPost = state.post;
    if (currentPost == null) return;

    final optimistic = currentPost.copyWith(
      isLiked: !currentPost.isLiked,
      likesCount: currentPost.likesCount + (currentPost.isLiked ? -1 : 1),
    );
    state = state.copyWith(post: optimistic);

    try {
      final refreshedPost = await _repository.toggleLike(currentPost.id);
      state = state.copyWith(post: refreshedPost);
    } catch (_) {
      state = state.copyWith(post: currentPost);
    }
  }

  Future<void> addComment({
    required String content,
    int? parentId,
  }) async {
    state = state.copyWith(isCommentSubmitting: true, errorMessage: null);
    try {
      await _repository.addComment(
        postId: _postId,
        content: content,
        parentId: parentId,
      );
      await load();
    } on DioException catch (error) {
      state = state.copyWith(
        isCommentSubmitting: false,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isCommentSubmitting: false,
        errorMessage: error.toString(),
      );
    } finally {
      state = state.copyWith(isCommentSubmitting: false);
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
