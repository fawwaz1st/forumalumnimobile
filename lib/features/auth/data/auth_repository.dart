import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/auth_models.dart';
import '../models/user.dart';
import '../../../services/api/mock_api_service.dart';
import '../../../services/api/real_api_service.dart';
import '../../../core/constants/app_config.dart';
import 'token_storage.dart';

class AuthRepository {
  AuthRepository(this._ref);
  final Ref _ref;

  RealApiService get _realApi => RealApiService();

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
      // Real API integration
      final response = await _realApi.login(email: email, password: password);
      
      final tokens = AuthTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
        expiresAt: DateTime.fromMillisecondsSinceEpoch(response['expires_at'] * 1000),
      );
      
      final user = User.fromJson(response['user']);

      await _ref.read(tokenStorageProvider).saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        remember: remember,
        email: remember ? email : null,
      );

      return AuthResponse(user: user, tokens: tokens);
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
      // Real API integration
      final response = await _realApi.register(name: name, email: email, password: password);
      
      final tokens = AuthTokens(
        accessToken: response['access_token'],
        refreshToken: response['refresh_token'],
        expiresAt: DateTime.fromMillisecondsSinceEpoch(response['expires_at'] * 1000),
      );
      
      final user = User.fromJson(response['user']);

      await _ref.read(tokenStorageProvider).saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        expiresAt: tokens.expiresAt,
        remember: true,
        email: email,
      );

      return AuthResponse(user: user, tokens: tokens);
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
        // Real API profile fetch
        final (accessToken, _, __) = await storage.readTokens();
        if (accessToken != null) {
          return await _realApi.getProfile(accessToken);
        }
        return null;
      }
    }
    if (await storage.hasRefreshToken()) {
      final refreshed = await refreshToken();
      if (refreshed != null) {
        if (AppConfig.useMock) {
          return _ref.read(mockApiServiceProvider).getProfile();
        } else {
          // Real API profile fetch after refresh
          final (accessToken, _, __) = await storage.readTokens();
          if (accessToken != null) {
            return await _realApi.getProfile(accessToken);
          }
          return null;
        }
      }
    }
    return null;
  }

  Future<AuthTokens?> refreshToken() async {
    final storage = _ref.read(tokenStorageProvider);
    final (_, rt, __) = await storage.readTokens();
    if (rt == null || rt.isEmpty) return null;

    if (AppConfig.useMock) {
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
    } else {
      // Real API refresh token
      try {
        final response = await _realApi.refreshToken(rt);
        final tokens = AuthTokens(
          accessToken: response['access_token'],
          refreshToken: response['refresh_token'],
          expiresAt: DateTime.fromMillisecondsSinceEpoch(response['expires_at'] * 1000),
        );
        await storage.saveTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: tokens.expiresAt,
        );
        return tokens;
      } catch (e) {
        // If refresh fails, clear stored tokens
        await storage.clear();
        return null;
      }
    }
  }

  String _randomToken({String prefix = 't'}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    final tail = List.generate(24, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$prefix.$tail';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));
