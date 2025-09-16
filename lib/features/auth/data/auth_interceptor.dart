import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_repository.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this.ref);
  final Ref ref;
  bool _isRefreshing = false;
  Dio? _client;

  void attach(Dio dio) {
    _client = dio;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final storage = ref.read(tokenStorageProvider);
      var (accessToken, _, expiresAt) = await storage.readTokens();
      // Refresh if about to expire
      if (accessToken != null) {
        if (expiresAt == null || DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 10)))) {
          final tokens = await ref.read(authRepositoryProvider).refreshToken();
          if (tokens != null) {
            accessToken = tokens.accessToken;
          }
        }
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      try {
        _isRefreshing = true;
        final tokens = await ref.read(authRepositoryProvider).refreshToken();
        _isRefreshing = false;
        if (tokens != null && _client != null) {
          final request = err.requestOptions;
          request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          final response = await _client!.fetch(request);
          return handler.resolve(response);
        }
      } catch (_) {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>((ref) => AuthInterceptor(ref));
