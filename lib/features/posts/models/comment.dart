import '../../auth/models/user.dart';

class Comment {
  final String id;
  final String postId;
  final String? parentId;
  final User author;
  final String contentMarkdown;
  final DateTime createdAt;
  final List<Comment> replies;
  final bool collapsed;

  Comment({
    required this.id,
    required this.postId,
    this.parentId,
    required this.author,
    required this.contentMarkdown,
    required this.createdAt,
    this.replies = const [],
    this.collapsed = false,
  });

  Comment copyWith({
    String? id,
    String? postId,
    String? parentId,
    User? author,
    String? contentMarkdown,
    DateTime? createdAt,
    List<Comment>? replies,
    bool? collapsed,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      author: author ?? this.author,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      collapsed: collapsed ?? this.collapsed,
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      parentId: json['parentId'] as String?,
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      contentMarkdown: json['contentMarkdown'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
      collapsed: json['collapsed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'parentId': parentId,
        'author': author.toJson(),
        'contentMarkdown': contentMarkdown,
        'createdAt': createdAt.toIso8601String(),
        'replies': replies.map((e) => e.toJson()).toList(),
        'collapsed': collapsed,
      };
}
