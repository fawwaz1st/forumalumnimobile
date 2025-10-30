import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import 'forum_user.dart';
import 'post_comment.dart';

class PostModel extends Equatable {
  const PostModel({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
    this.mediaUrl,
    this.mediaType,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.comments = const [],
  });

  final int id;
  final String content;
  final ForumUser author;
  final DateTime createdAt;
  final String? mediaUrl;
  final String? mediaType;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final List<PostComment> comments;

  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s lalu';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}h lalu';
    }

    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt);
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      author: ForumUser.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((item) => PostComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'author': author.toJson(),
        'created_at': createdAt.toIso8601String(),
        'media_url': mediaUrl,
        'media_type': mediaType,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'is_liked': isLiked,
        'comments': comments.map((comment) => comment.toJson()).toList(),
      };

  PostModel copyWith({
    int? id,
    String? content,
    ForumUser? author,
    DateTime? createdAt,
    String? mediaUrl,
    String? mediaType,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<PostComment>? comments,
  }) {
    return PostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        author,
        createdAt,
        mediaUrl,
        mediaType,
        likesCount,
        commentsCount,
        isLiked,
        comments,
      ];
}
