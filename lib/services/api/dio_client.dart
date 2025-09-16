import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
// Comment out Sentry import and interceptor due to compatibility issues
// import 'package:sentry_dio/sentry_dio.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../features/auth/data/auth_interceptor.dart';
import '../../core/constants/app_config.dart';
import 'retry_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  );
  final dio = Dio(baseOptions);
  final authInterceptor = ref.read(authInterceptorProvider);
  authInterceptor.attach(dio);
  dio.interceptors.addAll([
    authInterceptor,
    RetryInterceptor(
      dio: dio,
      retries: 3,
      retryDelays: const [
        Duration(milliseconds: 300),
        Duration(milliseconds: 800),
        Duration(seconds: 2),
      ],
    ),
    // SentryDioInterceptor(), // Commented out due to compatibility issues
  ]);

  // Certificate pinning (only if configured)
  final ioAdapter = IOHttpClientAdapter();
  ioAdapter.onHttpClientCreate = (client) {
    // Note: Custom badCertificateCallback validates against pinned fingerprints when provided
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
          if (AppConfig.pinnedSha256.isEmpty) {
            // No pin configured; accept system trusted only
            return false; // don't bypass; rely on system trust
          }
          try {
            final derBytes = Uint8List.fromList(cert.der);
            final sha256 = base64.encode(_sha256(derBytes));
            final printable = 'sha256/$sha256';
            return AppConfig.pinnedSha256.contains(printable);
          } catch (_) {
            return false;
          }
        };
    return client;
  };
  dio.httpClientAdapter = ioAdapter;
  return dio;
});

Uint8List _sha256(Uint8List input) =>
    Uint8List.fromList(crypto.sha256.convert(input).bytes);
