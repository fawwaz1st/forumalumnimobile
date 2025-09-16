import 'dart:async';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.retries = 3, List<Duration>? retryDelays})
      : retryDelays = retryDelays ?? const [Duration(milliseconds: 200), Duration(milliseconds: 600), Duration(seconds: 2)];

  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  bool _shouldRetry(DioException err) {
    // Retry on network errors and 5xx
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.badCertificate ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = err.response?.statusCode ?? 0;
    return status >= 500 && status < 600;
  }

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    var attempt = err.requestOptions.extra['__retry_attempt'] as int? ?? 0;
    if (attempt >= retries || !_shouldRetry(err)) {
      return handler.next(err);
    }
    // wait delay
    final delay = retryDelays[attempt < retryDelays.length ? attempt : retryDelays.length - 1];
    await Future<void>.delayed(delay);
    attempt += 1;
    // mark attempt
    err.requestOptions.extra['__retry_attempt'] = attempt;
    final reqOpts = Options(
      method: err.requestOptions.method,
      headers: err.requestOptions.headers,
      responseType: err.requestOptions.responseType,
      contentType: err.requestOptions.contentType,
      followRedirects: err.requestOptions.followRedirects,
      listFormat: err.requestOptions.listFormat,
      receiveDataWhenStatusError: err.requestOptions.receiveDataWhenStatusError,
      sendTimeout: err.requestOptions.sendTimeout,
      receiveTimeout: err.requestOptions.receiveTimeout,
    );
    try {
      final response = await dio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: reqOpts,
        cancelToken: err.requestOptions.cancelToken,
        onSendProgress: err.requestOptions.onSendProgress,
        onReceiveProgress: err.requestOptions.onReceiveProgress,
      );
      return handler.resolve(response);
    } catch (e) {
      return handler.next(e is DioException ? e : err);
    }
  }
}
