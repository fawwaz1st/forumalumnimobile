import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../auth_repository.dart';
import '../data/models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

enum AuthStatus { unauthenticated, authenticating, pendingApproval, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
    this.initialized = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
  final bool initialized;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isPendingApproval => status == AuthStatus.pendingApproval;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool? initialized,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      initialized: initialized ?? this.initialized,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        token,
        isLoading,
        errorMessage,
        initialized,
      ];
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository)
      : _apiClient = ApiClient(),
        super(const AuthState()) {
    unawaited(_loadExistingSession());
  }

  final AuthRepository _repository;
  final ApiClient _apiClient;

  Future<void> _loadExistingSession() async {
    try {
      final storedToken = await _apiClient.storage.read(key: 'token');
      if (storedToken == null) {
        state = state.copyWith(
          initialized: true,
          status: AuthStatus.unauthenticated,
          user: null,
          token: null,
        );
        return;
      }

      final user = await _repository.fetchProfile();
      final nextStatus = user.isApproved
          ? AuthStatus.authenticated
          : AuthStatus.pendingApproval;
      state = state.copyWith(
        status: nextStatus,
        user: user,
        token: storedToken,
        initialized: true,
      );
    } on DioException catch (error) {
      await _apiClient.clearToken();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        token: null,
        initialized: true,
        errorMessage: _mapDioError(error),
      );
    } catch (_) {
      await _apiClient.clearToken();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        token: null,
        initialized: true,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;
    print('🔐 Starting login process for: $email');
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      status: AuthStatus.authenticating,
    );

    try {
      final session = await _repository.login(email: email, password: password);
      print('✅ Login successful! Token: ${session.token.substring(0, 20)}...');
      print('👤 User: ${session.user.name} (${session.user.email})');
      
      await _apiClient.saveToken(session.token);
      print('💾 Token saved to storage');
      
      // Save user profile data from login response to secure storage
      await _apiClient.storage.write(key: 'user_profile', value: jsonEncode(session.user.toJson()));
      print('📄 User profile data saved to storage');

      final nextStatus = session.user.isApproved
          ? AuthStatus.authenticated
          : AuthStatus.pendingApproval;

      print('📊 User approval status: ${session.user.isApproved} -> Status: $nextStatus');

      state = state.copyWith(
        isLoading: false,
        status: nextStatus,
        user: session.user,
        token: session.token,
        initialized: true,
      );
    } on DioException catch (error) {
      print('❌ Login failed with DioException: ${error.message}');
      print('📍 Response: ${error.response?.data}');
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        errorMessage: _mapDioError(error),
      );
    } catch (error) {
      print('❌ Login failed with error: $error');
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapDioError(error),
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (state.token == null) return;
    try {
      final user = await _repository.fetchProfile();
      final nextStatus = user.isApproved
          ? AuthStatus.authenticated
          : AuthStatus.pendingApproval;
      state = state.copyWith(
        user: user,
        status: nextStatus,
        errorMessage: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(errorMessage: _mapDioError(error));
    } catch (error) {
      state = state.copyWith(errorMessage: error.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // ignore so user still gets logged out locally
    }
    await _apiClient.clearToken();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      token: null,
      errorMessage: null,
    );
  }

  String _mapDioError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> data = error.response!.data as Map<String, dynamic>;
      if (data['message'] is String) {
        return data['message'] as String;
      }
      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;
        final firstKey = errors.keys.first;
        final dynamic value = errors[firstKey];
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        return value.toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return 'Permintaan gagal: ${error.response?.statusCode ?? ''}';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan yang tidak diketahui';
    }
  }
}
