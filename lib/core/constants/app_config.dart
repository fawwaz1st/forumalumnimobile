class AppConfig {
  // Set these via --dart-define on run/build
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );
  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  // Certificate pinning via SHA-256 (base64) fingerprints of server certificate (DER)
  // Example value: "sha256/47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU="
  static const List<String> pinnedSha256 = [];
}
