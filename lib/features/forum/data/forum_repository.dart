import 'package:dio/dio.dart';

import 'package:forum_alumni/core/services/api_client.dart';
import 'models/post_model.dart';
import 'models/post_comment.dart';

class ForumRepository {
  ForumRepository({Dio? client}) : _client = client ?? ApiClient().client;

  final Dio _client;

  Future<PostPagination> fetchPosts({int page = 1, int perPage = 10}) async {
    final response = await _client.get(
      '/posts',
      queryParameters: {
        'page': page,
        'per_page': perPage,
      },
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> items = response.data['data'] as List<dynamic>;
      final posts = items
          .map((item) => PostModel.fromJson(item as Map<String, dynamic>))
          .toList();
      final meta = response.data['meta'] as Map<String, dynamic>?;
      final lastPage = meta != null ? meta['last_page'] as int? ?? page : page;
      return PostPagination(
        posts: posts,
        currentPage: page,
        lastPage: lastPage,
      );
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal memuat postingan',
    );
  }

  Future<PostModel> fetchPostDetail(int id) async {
    final response = await _client.get('/posts/$id');

    if (response.statusCode == 200 && response.data['success'] == true) {
      return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal memuat detail postingan',
    );
  }

  Future<PostModel> createPost({
    required String content,
    String? mediaPath,
    String? mediaType,
    List<int>? mediaBytes,
    String? mediaFilename,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty && mediaBytes == null && mediaPath == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.badResponse,
        error: 'Konten tidak boleh kosong',
        response: Response(
          requestOptions: RequestOptions(path: '/posts'),
          statusCode: 400,
          data: {'message': 'Konten tidak boleh kosong'},
        ),
      );
    }
    final formMap = <String, dynamic>{
      'content': trimmedContent,
    };

    if (mediaBytes != null && mediaFilename != null) {
      formMap['media'] = MultipartFile.fromBytes(
        mediaBytes,
        filename: mediaFilename,
      );
    } else if (mediaPath != null) {
      formMap['media'] = await MultipartFile.fromFile(
        mediaPath,
        filename: mediaFilename ?? 'upload',
      );
    }
    final resolvedMediaType = () {
      if (mediaType != null && mediaType.isNotEmpty) {
        return mediaType;
      }
      if (mediaBytes != null || mediaPath != null) {
        return 'image';
      }
      return 'text';
    }();

    formMap['media_type'] = resolvedMediaType;

    final data = FormData.fromMap(formMap);

    final response = await _client.post('/posts', data: data);

    if (response.statusCode == 201 && response.data['success'] == true) {
      return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal membuat postingan',
    );
  }

  Future<PostModel> toggleLike(int postId) async {
    final response = await _client.post('/posts/$postId/like');
    if (response.statusCode == 200 && response.data['success'] == true) {
      return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal memperbarui like',
    );
  }

  Future<PostComment> addComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    final response = await _client.post(
      '/posts/$postId/comments',
      data: {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      },
    );

    if (response.statusCode == 201 && response.data['success'] == true) {
      return PostComment.fromJson(response.data['data'] as Map<String, dynamic>);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal menambahkan komentar',
    );
  }
}

class PostPagination {
  const PostPagination({
    required this.posts,
    required this.currentPage,
    required this.lastPage,
  });

  final List<PostModel> posts;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;
}
