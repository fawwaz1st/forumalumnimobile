import 'package:equatable/equatable.dart';

enum NotificationType {
  like,
  comment,
  mention,
  follow,
  system,
}

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.relatedPostId,
    this.relatedUserId,
    this.actionUrl,
    this.imageUrl,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedPostId;
  final String? relatedUserId;
  final String? actionUrl;
  final String? imageUrl;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: _typeFromString(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      relatedPostId: json['related_post_id']?.toString(),
      relatedUserId: json['related_user_id']?.toString(),
      actionUrl: json['action_url']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'related_post_id': relatedPostId,
      'related_user_id': relatedUserId,
      'action_url': actionUrl,
      'image_url': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? relatedPostId,
    String? relatedUserId,
    String? actionUrl,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedPostId: relatedPostId ?? this.relatedPostId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'mention':
        return NotificationType.mention;
      case 'follow':
        return NotificationType.follow;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        isRead,
        createdAt,
        relatedPostId,
        relatedUserId,
        actionUrl,
        imageUrl,
      ];
}
