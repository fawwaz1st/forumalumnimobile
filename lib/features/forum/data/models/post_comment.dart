import 'package:equatable/equatable.dart';

import 'forum_user.dart';

class PostComment extends Equatable {
  const PostComment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.parentId,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  final int id;
  final String content;
  final ForumUser author;
  final DateTime createdAt;
  final int? parentId;
  final int likesCount;
  final bool isLiked;
  final List<PostComment> replies;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      author: ForumUser.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      parentId: json['parent_id'] as int?,
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((item) => PostComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'author': author.toJson(),
        'created_at': createdAt.toIso8601String(),
        'parent_id': parentId,
        'likes_count': likesCount,
        'is_liked': isLiked,
        'replies': replies.map((reply) => reply.toJson()).toList(),
      };

  PostComment copyWith({
    int? id,
    String? content,
    ForumUser? author,
    DateTime? createdAt,
    int? parentId,
    int? likesCount,
    bool? isLiked,
    List<PostComment>? replies,
  }) {
    return PostComment(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        author,
        createdAt,
        parentId,
        likesCount,
        isLiked,
        replies,
      ];
}
