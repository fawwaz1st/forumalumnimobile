import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  const ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.angkatan,
    required this.status,
    this.phone,
    this.job,
    this.avatarUrl,
  });

  final int id;
  final int userId;
  final String name;
  final String email;
  final String angkatan;
  final String status;
  final String? phone;
  final String? job;
  final String? avatarUrl;

  bool get isApproved => status.toLowerCase() == 'approved';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    print('ProfileModel.fromJson: $json'); // Debug print
    
    // Handle different possible field names based on database structure
    final id = json['id'] as int? ?? 0;
    final userId = json['user_id'] as int? ?? json['userId'] as int? ?? 0;
    
    // Name can be 'nama', 'name', or 'full_name'
    final name = json['nama'] as String? ?? 
                 json['name'] as String? ?? 
                 json['full_name'] as String? ?? '';
    
    final email = json['email'] as String? ?? '';
    
    // Angkatan can be string or number
    final angkatan = json['angkatan']?.toString() ?? 
                     json['graduation_year']?.toString() ?? 
                     json['tahun_lulus']?.toString() ?? '';
    
    // Status can be 'status', 'current_status', etc.
    final status = json['status'] as String? ?? 
                   json['current_status'] as String? ?? 
                   'belum bekerja';
    
    // Phone number variations
    final phone = json['no_hp'] as String? ?? 
                  json['phone'] as String? ?? 
                  json['nomor_hp'] as String?;
    
    // Job/work variations
    final job = json['pekerjaan'] as String? ?? 
                json['job'] as String? ?? 
                json['current_job'] as String? ?? 
                json['work'] as String?;
    
    // Avatar/photo variations
    final avatarUrl = json['foto'] as String? ?? 
                      json['avatar'] as String? ?? 
                      json['avatar_url'] as String? ?? 
                      json['profile_photo'] as String?;
    
    return ProfileModel(
      id: id,
      userId: userId,
      name: name,
      email: email,
      angkatan: angkatan,
      status: status,
      phone: phone,
      job: job,
      avatarUrl: avatarUrl,
    );
  }

  ProfileModel copyWith({
    String? name,
    String? email,
    String? angkatan,
    String? status,
    String? phone,
    String? job,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      angkatan: angkatan ?? this.angkatan,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      job: job ?? this.job,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        email,
        angkatan,
        status,
        phone,
        job,
        avatarUrl,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nama': name,
      'name': name, // Support both formats
      'email': email,
      'angkatan': angkatan,
      'status': status,
      'no_hp': phone,
      'phone': phone, // Support both formats
      'pekerjaan': job,
      'job': job, // Support both formats
      'foto': avatarUrl,
      'avatar': avatarUrl, // Support both formats
    };
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, userId: $userId, name: $name, email: $email, angkatan: $angkatan, status: $status, phone: $phone, job: $job, avatarUrl: $avatarUrl)';
  }
}
