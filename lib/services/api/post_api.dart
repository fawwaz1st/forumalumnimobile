import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/posts/data/posts_remote.dart';
import '../../features/posts/models/post.dart';
import '../../features/posts/models/category.dart';
import '../../features/posts/models/tag.dart';
import '../../features/posts/models/comment.dart';
import '../../features/auth/models/user.dart';
import 'dio_client.dart';

final postApiProvider = Provider<PostsRemoteDio>((ref) {
  final dio = ref.read(dioProvider);
  return PostsRemoteDio(dio);
});

class PostsRemoteDio implements IPostsRemote {
  PostsRemoteDio(this._dio);
  final Dio _dio;

  @override
  Future<List<Category>> listCategories() async {
    try {
      final res = await _dio.get('/categories');
      final data = _extractList(res.data);
      return data.map((e) => Category.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return const [
        Category(id: 'all', name: 'Semua', color: 0xFF607D8B),
      ];
    }
  }

  @override
  Future<List<Tag>> listTags() async {
    try {
      final res = await _dio.get('/tags');
      final data = _extractList(res.data);
      return data.map((e) => Tag.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return const <Tag>[];
    }
  }

  @override
  Future<List<Post>> fetchPosts({required int page, required int limit, String? query, String? categoryId}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') params['categoryId'] = categoryId;
    try {
      final res = await _dio.get('/posts', queryParameters: params);
      final list = _extractList(res.data);
      return list.map((e) => _mapPost(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Post> getPost(String id) async {
    final res = await _dio.get('/posts/$id');
    final map = _extractMap(res.data);
    return _mapPost(map);
  }

  @override
  Future<Post> votePost({required String postId, required int vote}) async {
    try {
      await _dio.post('/posts/$postId/vote', data: {'vote': vote});
    } catch (_) {}
    return getPost(postId);
  }

  @override
  Future<Post> bookmarkPost({required String postId, required bool bookmarked}) async {
    try {
      await _dio.post('/posts/$postId/bookmark', data: {'bookmarked': bookmarked});
    } catch (_) {}
    return getPost(postId);
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    try {
      final res = await _dio.get('/posts/$postId/comments');
      final list = _extractList(res.data);
      return list.map((e) => Comment.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return const <Comment>[];
    }
  }

  @override
  Future<Comment> addReply({required String postId, String? parentId, required String contentMarkdown}) async {
    final res = await _dio.post('/posts/$postId/comments', data: {
      'parentId': parentId,
      'contentMarkdown': contentMarkdown,
    });
    final map = _extractMap(res.data);
    return Comment.fromJson(map);
  }

  @override
  Future<Post> createPost({required String title, required String contentMarkdown, String? categoryId, List<String> tagIds = const []}) async {
    final res = await _dio.post('/posts', data: {
      'title': title,
      'contentMarkdown': contentMarkdown,
      'categoryId': categoryId,
      'tagIds': tagIds,
    });
    final map = _extractMap(res.data);
    return _mapPost(map);
  }

  @override
  Future<Post> updatePost({required String id, String? title, String? contentMarkdown, String? categoryId, List<String>? tagIds}) async {
    final res = await _dio.put('/posts/$id', data: {
      if (title != null) 'title': title,
      if (contentMarkdown != null) 'contentMarkdown': contentMarkdown,
      if (categoryId != null) 'categoryId': categoryId,
      if (tagIds != null) 'tagIds': tagIds,
    });
    final map = _extractMap(res.data);
    return _mapPost(map);
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map && data['data'] is Map) return Map<String, dynamic>.from(data['data'] as Map);
    throw Exception('Unexpected response');
  }

  Post _mapPost(Map<String, dynamic> j) {
    final authorMap = Map<String, dynamic>.from(j['author'] as Map? ?? const {});
    final user = User(
      id: authorMap['id']?.toString() ?? 'u_${j['id']}',
      name: authorMap['name']?.toString() ?? 'Anonim',
      email: authorMap['email']?.toString() ?? '',
      avatar: authorMap['avatar']?.toString(),
    );
    final tags = (j['tags'] as List?)?.map((e) {
      if (e is String) {
        return Tag(id: e, name: e, color: 0xFF9C27B0);
      }
      final m = Map<String, dynamic>.from(e as Map);
      return Tag(
        id: m['id']?.toString() ?? (m['name']?.toString() ?? 'tag'),
        name: m['name']?.toString() ?? 'tag',
        color: (m['color'] is int) ? m['color'] as int : 0xFF9C27B0,
      );
    }).toList() ?? const <Tag>[];

    DateTime createdAt;
    final ts = j['timestamp'] ?? j['createdAt'] ?? j['created_at'];
    if (ts is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return Post(
      id: j['id'].toString(),
      title: j['title']?.toString() ?? '',
      excerpt: (j['excerpt'] ?? j['body'])?.toString(),
      contentMarkdown: j['contentMarkdown']?.toString() ?? '',
      author: user,
      createdAt: createdAt,
      category: null,
      tags: tags,
      votes: (j['likeCount'] as num?)?.toInt() ?? (j['votes'] as num?)?.toInt() ?? 0,
      userVote: (j['userVote'] as num?)?.toInt() ?? 0,
      commentsCount: (j['commentCount'] as num?)?.toInt() ?? (j['commentsCount'] as num?)?.toInt() ?? 0,
      bookmarked: j['bookmarked'] == true,
      imageUrl: (j['imageUrl'] ?? j['image_url'])?.toString(),
    );
  }
}
