import 'package:dio/dio.dart';

import 'package:forum_alumni/core/services/api_client.dart';
import 'models/admin_alumni.dart';

class AdminRepository {
  AdminRepository({Dio? client}) : _client = client ?? ApiClient().client;

  final Dio _client;

  Future<List<AdminAlumni>> fetchPendingAlumni() async {
    final response = await _client.get('/admin/alumni_profiles', queryParameters: {
      'status': 'pending',
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data
          .map((item) => AdminAlumni.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal memuat data alumni',
    );
  }

  Future<void> verifyAlumni({required int alumniId, required bool approved}) async {
    await _client.post(
      '/admin/alumni_profiles/$alumniId/verify',
      data: {
        'status': approved ? 'approved' : 'rejected',
      },
    );
  }

  Future<void> deletePost(int postId) async {
    await _client.delete('/admin/posts/$postId');
  }

  Future<void> deleteComment(int commentId) async {
    await _client.delete('/admin/comments/$commentId');
  }
}
