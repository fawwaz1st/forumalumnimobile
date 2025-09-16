import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../storage/storage.dart';

class TokenKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const expiresAt = 'expires_at'; // ISO8601 string
  static const rememberMe = 'remember_me'; // 'true' | 'false'
  static const savedEmail = 'saved_email';
}

class TokenStorage {
  TokenStorage(this._secureStorage);
  final FlutterSecureStorage _secureStorage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    bool remember = true,
    String? email,
  }) async {
    await _secureStorage.write(key: TokenKeys.accessToken, value: accessToken);
    await _secureStorage.write(key: TokenKeys.refreshToken, value: refreshToken);
    await _secureStorage.write(key: TokenKeys.expiresAt, value: expiresAt.toIso8601String());
    await _secureStorage.write(key: TokenKeys.rememberMe, value: remember.toString());
    if (email != null) {
      await _secureStorage.write(key: TokenKeys.savedEmail, value: email);
    }
  }

  Future<(String? accessToken, String? refreshToken, DateTime? expiresAt)> readTokens() async {
    final at = await _secureStorage.read(key: TokenKeys.accessToken);
    final rt = await _secureStorage.read(key: TokenKeys.refreshToken);
    final exp = await _secureStorage.read(key: TokenKeys.expiresAt);
    final expDt = exp != null ? DateTime.tryParse(exp) : null;
    return (at, rt, expDt);
  }

  Future<bool> hasValidAccessToken() async {
    final (at, _, exp) = await readTokens();
    if (at == null || at.isEmpty) return false;
    if (exp == null) return false;
    return DateTime.now().isBefore(exp);
  }

  Future<bool> hasRefreshToken() async {
    final (_, rt, __) = await readTokens();
    return rt != null && rt.isNotEmpty;
  }

  Future<bool> rememberMe() async {
    final value = await _secureStorage.read(key: TokenKeys.rememberMe);
    return value == 'true';
  }

  Future<String?> savedEmail() async {
    return _secureStorage.read(key: TokenKeys.savedEmail);
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: TokenKeys.accessToken);
    await _secureStorage.delete(key: TokenKeys.refreshToken);
    await _secureStorage.delete(key: TokenKeys.expiresAt);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenStorage(storage);
});
