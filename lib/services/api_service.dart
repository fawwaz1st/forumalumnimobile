import 'dart:convert';

import 'package:http/http.dart' as http;

/// Basic service layer to communicate with the Laravel REST API.
///
/// Replace [defaultBaseUrl] with the URL of your Laravel deployment, e.g.
/// `http://10.0.2.2:8000/api` for Android emulator or `http://localhost:8000/api`
/// when running Flutter for web/desktop in the same machine.
class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  final http.Client _client;
  final String baseUrl;

  Uri _resolve(String path) => Uri.parse('$baseUrl$path');

  /// Example GET request: fetch alumni list
  Future<List<dynamic>> fetchAlumniList() async {
    final response = await _client.get(_resolve('/alumni_profiles'));

    if (response.statusCode != 200) {
      throw ApiException(
        'Gagal memuat data alumni',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return List<dynamic>.from(decoded['data'] as List);
    }

    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }

    throw const ApiException('Format respons tidak dikenali');
  }

  /// Example POST request: create alumni record
  Future<Map<String, dynamic>> createAlumni(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _resolve('/alumni_profiles'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 201) {
      throw ApiException(
        'Gagal membuat data alumni',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException('Format respons tidak dikenali');
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.body,
  });

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) buffer.write(' (status: $statusCode)');
    if (body != null) buffer.write(' -> $body');
    return buffer.toString();
  }
}
