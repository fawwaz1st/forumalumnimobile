import '../models/post.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/comment.dart';

abstract class IPostsRemote {
  Future<List<Category>> listCategories();
  Future<List<Tag>> listTags();

  Future<List<Post>> fetchPosts({
    required int page,
    required int limit,
    String? query,
    String? categoryId,
  });

  Future<Post> getPost(String id);
  Future<Post> votePost({required String postId, required int vote});
  Future<Post> bookmarkPost({required String postId, required bool bookmarked});
  Future<List<Comment>> getComments(String postId);
  Future<Comment> addReply({required String postId, String? parentId, required String contentMarkdown});
  Future<Post> createPost({
    required String title,
    required String contentMarkdown,
    String? categoryId,
    List<String> tagIds,
  });
  Future<Post> updatePost({
    required String id,
    String? title,
    String? contentMarkdown,
    String? categoryId,
    List<String>? tagIds,
  });
}
