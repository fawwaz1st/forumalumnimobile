import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Environment variables from .env file or --dart-define
  static String get appEnv => dotenv.env['APP_ENV'] ?? 
    const String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 
    const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.example.com/v1');
  
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? 
    const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  
  static bool get useMock => dotenv.env['USE_MOCK']?.toLowerCase() == 'true' ||
    const bool.fromEnvironment('USE_MOCK', defaultValue: false);

  // Certificate pinning via SHA-256 (base64) fingerprints of server certificate (DER)
  static List<String> get pinnedSha256 {
    final pinned = dotenv.env['PINNED_SHA256'];
    return pinned != null ? [pinned] : [];
  }
}
