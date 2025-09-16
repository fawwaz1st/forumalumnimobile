import 'dart:convert';
import '../../auth/models/user.dart';
import 'category.dart';
import 'tag.dart';

class Post {
  final String id;
  final String title;
  final String? excerpt;
  final String contentMarkdown;
  final User author;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Category? category;
  final List<Tag> tags;
  final int votes;
  final int userVote; // -1, 0, 1
  final int commentsCount;
  final bool bookmarked;
  final String? imageUrl;

  Post({
    required this.id,
    required this.title,
    this.excerpt,
    required this.contentMarkdown,
    required this.author,
    required this.createdAt,
    this.updatedAt,
    this.category,
    this.tags = const [],
    this.votes = 0,
    this.userVote = 0,
    this.commentsCount = 0,
    this.bookmarked = false,
    this.imageUrl,
  });

  Post copyWith({
    String? id,
    String? title,
    String? excerpt,
    String? contentMarkdown,
    User? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    List<Tag>? tags,
    int? votes,
    int? userVote,
    int? commentsCount,
    bool? bookmarked,
    String? imageUrl,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      votes: votes ?? this.votes,
      userVote: userVote ?? this.userVote,
      commentsCount: commentsCount ?? this.commentsCount,
      bookmarked: bookmarked ?? this.bookmarked,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String?,
      contentMarkdown: json['contentMarkdown'] as String? ?? '',
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      category: json['category'] != null ? Category.fromJson(json['category'] as Map<String, dynamic>) : null,
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => Tag.fromJson(e as Map<String, dynamic>)).toList(),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      userVote: (json['userVote'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      bookmarked: json['bookmarked'] as bool? ?? false,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'contentMarkdown': contentMarkdown,
      'author': author.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'category': category?.toJson(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'votes': votes,
      'userVote': userVote,
      'commentsCount': commentsCount,
      'bookmarked': bookmarked,
      'imageUrl': imageUrl,
    };
  }

  static List<Post> listFromJsonString(String str) {
    final data = jsonDecode(str) as List<dynamic>;
    return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJsonString(List<Post> posts) {
    return jsonEncode(posts.map((e) => e.toJson()).toList());
  }
}
