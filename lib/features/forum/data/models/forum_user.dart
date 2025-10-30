import 'package:equatable/equatable.dart';

class ForumUser extends Equatable {
  const ForumUser({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.role,
  });

  final int id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? role;

  factory ForumUser.fromJson(Map<String, dynamic> json) {
    return ForumUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '-',
      email: json['email'] as String?,
      avatarUrl: json['avatar'] as String? ?? json['avatar_url'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatarUrl,
        'role': role,
      };

  @override
  List<Object?> get props => [id, name, email, avatarUrl, role];
}
