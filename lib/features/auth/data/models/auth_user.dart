import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.status,
    this.emailVerifiedAt,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? status;
  final DateTime? emailVerifiedAt;

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isApproved => isAdmin || status?.toLowerCase() == 'approved';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'alumni',
      avatarUrl: json['avatar'] as String?,
      status: json['status'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatarUrl,
        'status': status,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
      };

  AuthUser copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    String? status,
    DateTime? emailVerifiedAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        avatarUrl,
        status,
        emailVerifiedAt,
      ];
}
