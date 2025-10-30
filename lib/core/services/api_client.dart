import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:forum_alumni/core/config/api_config.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    _storage = const FlutterSecureStorage();
    _connectivity = Connectivity();
    
    // Add retry interceptor for network issues
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check connectivity before request
          final connectivityResult = await _connectivity.checkConnectivity();
          if (connectivityResult == ConnectivityResult.none) {
            print('❌ No internet connection detected!');
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Tidak ada koneksi internet. Pastikan perangkat terhubung ke WiFi atau data seluler.',
                type: DioExceptionType.connectionError,
              ),
            );
          }
          
          final token = await _storage.read(key: 'token');
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          } else {
            options.headers['Content-Type'] = 'application/json';
          }

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token found and added to request: ${token.substring(0, 20)}...');
          } else {
            print('❌ No token found in storage!');
          }
          
          // Debug logging
          if (kDebugMode) {
            print('🌐 Network: $connectivityResult');
            print('🚀 API Request: ${options.method} ${options.baseUrl}${options.path}');
            print('📋 Headers: ${options.headers}');
            print('📦 Data: ${options.data}'); 
            print('⏱️ Timeout: ${options.connectTimeout} / ${options.receiveTimeout}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Debug logging
          if (kDebugMode) {
            print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
            print('📄 Response Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          // Debug logging
          if (kDebugMode) {
            print('❌ API Error: ${error.requestOptions.method} ${error.requestOptions.path}');
            print('📍 Status Code: ${error.response?.statusCode}');
            print('💬 Error Message: ${error.message}');
            print('📄 Error Data: ${error.response?.data}');
          }
          
          // Retry logic for network errors
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
                
            final retryCount = error.requestOptions.extra['retryCount'] ?? 0;
            if (retryCount < 2) {
              print('🔄 Retrying request... (${retryCount + 1}/2)');
              error.requestOptions.extra['retryCount'] = retryCount + 1;
              
              // Wait before retry
              await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
              
              // Check connectivity again
              final connectivityResult = await _connectivity.checkConnectivity();
              if (connectivityResult != ConnectivityResult.none) {
                try {
                  final response = await _dio.fetch(error.requestOptions);
                  return handler.resolve(response);
                } catch (e) {
                  // Continue to original error handling
                }
              }
            }
          }
          
          return handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  late final FlutterSecureStorage _storage;
  late final Connectivity _connectivity;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;
  Dio get client => _dio;
  FlutterSecureStorage get storage => _storage;

  Future<void> clearToken() => _storage.delete(key: 'token');
  Future<void> saveToken(String token) =>
      _storage.write(key: 'token', value: token);
}
