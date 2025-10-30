import 'package:equatable/equatable.dart';

class AdminAlumni extends Equatable {
  const AdminAlumni({
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

  bool get isPending => status.toLowerCase() == 'pending';

  factory AdminAlumni.fromJson(Map<String, dynamic> json) {
    return AdminAlumni(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['nama'] as String? ?? json['name'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      angkatan: json['angkatan']?.toString() ?? '-',
      status: json['status'] as String? ?? 'pending',
      phone: json['no_hp'] as String?,
      job: json['pekerjaan'] as String?,
      avatarUrl: json['foto'] as String?,
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
}
