import 'user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isAboutToExpire => DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 2)));
}

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  const AuthResponse({required this.user, required this.tokens});
}
