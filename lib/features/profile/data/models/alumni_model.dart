import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alumni_model.g.dart';

@JsonSerializable()
class AlumniModel extends Equatable {
  const AlumniModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nim,
    required this.graduationYear,
    required this.major,
    required this.currentStatus,
    required this.isVerified,
    this.avatar,
    this.phone,
    this.currentJob,
    this.company,
    this.bio,
    this.linkedIn,
    this.instagram,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String nim;
  @JsonKey(name: 'graduation_year')
  final int graduationYear;
  final String major;
  @JsonKey(name: 'current_status')
  final String currentStatus;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  final String? avatar;
  final String? phone;
  @JsonKey(name: 'current_job')
  final String? currentJob;
  final String? company;
  final String? bio;
  @JsonKey(name: 'linked_in')
  final String? linkedIn;
  final String? instagram;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  factory AlumniModel.fromJson(Map<String, dynamic> json) => _$AlumniModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlumniModelToJson(this);

  AlumniModel copyWith({
    String? id,
    String? name,
    String? email,
    String? nim,
    int? graduationYear,
    String? major,
    String? currentStatus,
    bool? isVerified,
    String? avatar,
    String? phone,
    String? currentJob,
    String? company,
    String? bio,
    String? linkedIn,
    String? instagram,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlumniModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      nim: nim ?? this.nim,
      graduationYear: graduationYear ?? this.graduationYear,
      major: major ?? this.major,
      currentStatus: currentStatus ?? this.currentStatus,
      isVerified: isVerified ?? this.isVerified,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      currentJob: currentJob ?? this.currentJob,
      company: company ?? this.company,
      bio: bio ?? this.bio,
      linkedIn: linkedIn ?? this.linkedIn,
      instagram: instagram ?? this.instagram,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        nim,
        graduationYear,
        major,
        currentStatus,
        isVerified,
        avatar,
        phone,
        currentJob,
        company,
        bio,
        linkedIn,
        instagram,
        createdAt,
        updatedAt,
      ];
}
