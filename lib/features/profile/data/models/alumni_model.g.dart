// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alumni_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlumniModel _$AlumniModelFromJson(Map<String, dynamic> json) => AlumniModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      nim: json['nim'] as String,
      graduationYear: json['graduation_year'] as int,
      major: json['major'] as String,
      currentStatus: json['current_status'] as String,
      isVerified: json['is_verified'] as bool,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      currentJob: json['current_job'] as String?,
      company: json['company'] as String?,
      bio: json['bio'] as String?,
      linkedIn: json['linked_in'] as String?,
      instagram: json['instagram'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AlumniModelToJson(AlumniModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'nim': instance.nim,
      'graduation_year': instance.graduationYear,
      'major': instance.major,
      'current_status': instance.currentStatus,
      'is_verified': instance.isVerified,
      'avatar': instance.avatar,
      'phone': instance.phone,
      'current_job': instance.currentJob,
      'company': instance.company,
      'bio': instance.bio,
      'linked_in': instance.linkedIn,
      'instagram': instance.instagram,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
