import 'package:dio/dio.dart';

import 'package:forum_alumni/core/services/api_client.dart';
import 'data/models/auth_user.dart';

class AuthRepository {
  AuthRepository({Dio? client}) : _client = client ?? ApiClient().client;

  final Dio _client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['data']['token'] as String;
        final user = AuthUser.fromJson(response.data['data']['user']);
        return AuthSession(token: token, user: user);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: response.data['message'] ?? 'Login gagal',
      );
    } on DioException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          error: error,
          type: DioExceptionType.unknown,
        ),
        stackTrace,
      );
    }
  }

  Future<void> logout() async {
    await _client.post('/logout');
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _client.post(
      '/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<AuthUser> fetchProfile() async {
    final response = await _client.get('/profile');

    if (response.statusCode == 200 && response.data['success'] == true) {
      return AuthUser.fromJson(response.data['data']);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      error: response.data['message'] ?? 'Gagal memuat profil',
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;
}
