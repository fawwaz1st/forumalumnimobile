import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/auth_models.dart';
import '../models/user.dart';
import '../../../services/api/mock_api_service.dart';
import '../../../core/constants/app_config.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository(this._ref);
  final Ref _ref;

  Future<AuthResponse> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    // Use mock only when explicitly enabled, otherwise throw for real API integration
    if (AppConfig.useMock) {
      final api = _ref.read(mockApiServiceProvider);
      final user = await api.login(email: email, password: password);

      // Mock tokens
      final now = DateTime.now();
      final tokens = AuthTokens(
        accessToken: _randomToken(prefix: 'access'),
        refreshToken: _randomToken(prefix: 'refresh'),
        expiresAt: now.add(const Duration(minutes: 15)),
      );

      await _ref.read(tokenStorageProvider).saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: tokens.expiresAt,
            remember: remember,
            email: remember ? email : null,
          );

      return AuthResponse(user: user, tokens: tokens);
    } else {
      // Real API integration should be implemented here
      throw UnimplementedError('Real API authentication not implemented yet. Set USE_MOCK=true for development.');
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMock) {
      final api = _ref.read(mockApiServiceProvider);
      final user = await api.register(name: name, email: email, password: password);

      final now = DateTime.now();
      final tokens = AuthTokens(
        accessToken: _randomToken(prefix: 'access'),
        refreshToken: _randomToken(prefix: 'refresh'),
        expiresAt: now.add(const Duration(minutes: 15)),
      );

      await _ref.read(tokenStorageProvider).saveTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: tokens.expiresAt,
            remember: true,
            email: email,
          );

      return AuthResponse(user: user, tokens: tokens);
    } else {
      throw UnimplementedError('Real API registration not implemented yet. Set USE_MOCK=true for development.');
    }
  }

  Future<void> logout() async {
    await _ref.read(tokenStorageProvider).clear();
  }

  Future<User?> restoreSession() async {
    final storage = _ref.read(tokenStorageProvider);
    if (await storage.hasValidAccessToken()) {
      if (AppConfig.useMock) {
        return _ref.read(mockApiServiceProvider).getProfile();
      } else {
        // Real API should fetch profile here
        throw UnimplementedError('Real API profile fetch not implemented yet. Set USE_MOCK=true for development.');
      }
    }
    if (await storage.hasRefreshToken()) {
      final refreshed = await refreshToken();
      if (refreshed != null) {
        if (AppConfig.useMock) {
          return _ref.read(mockApiServiceProvider).getProfile();
        } else {
          throw UnimplementedError('Real API profile fetch not implemented yet. Set USE_MOCK=true for development.');
        }
      }
    }
    return null;
  }

  Future<AuthTokens?> refreshToken() async {
    final storage = _ref.read(tokenStorageProvider);
    final (_, rt, __) = await storage.readTokens();
    if (rt == null || rt.isEmpty) return null;

    final now = DateTime.now();
    final tokens = AuthTokens(
      accessToken: _randomToken(prefix: 'access'),
      refreshToken: rt, // keep same refresh for mock
      expiresAt: now.add(const Duration(minutes: 15)),
    );
    await storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
    );
    return tokens;
  }

  String _randomToken({String prefix = 't'}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final tail = List.generate(24, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$prefix.$tail';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));
