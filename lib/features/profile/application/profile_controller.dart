import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/features/profile/data/models/profile_model.dart';
import 'package:forum_alumni/features/profile/data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository);
});

enum ProfileStatus { initial, loading, loaded, error }

enum ProfileAction { update, uploadAvatar }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.isSubmitting = false,
    this.lastAction,
  });

  final ProfileStatus status;
  final ProfileModel? profile;
  final String? errorMessage;
  final bool isSubmitting;
  final ProfileAction? lastAction;

  bool get isLoading => status == ProfileStatus.loading;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileModel? profile,
    String? errorMessage,
    bool? isSubmitting,
    ProfileAction? lastAction,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastAction: lastAction,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, isSubmitting, lastAction];
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository) : super(const ProfileState()) {
    unawaited(loadProfile());
  }

  final ProfileRepository _repository;

  Future<void> loadProfile() async {
    print('🔄 ProfileNotifier: Starting loadProfile');
    state = state.copyWith(status: ProfileStatus.loading, errorMessage: null);
    try {
      final profile = await _repository.fetchProfile();
      print('✅ ProfileNotifier: Profile loaded successfully: $profile');
      state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        errorMessage: null,
      );
    } on DioException catch (error) {
      print('❌ ProfileNotifier: DioException error: ${error.message}');
      print('📍 Error response: ${error.response?.data}');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      print('❌ ProfileNotifier: General error: $error');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? angkatan,
    String? status,
    String? phone,
    String? job,
  }) async {
    state = state.copyWith(isSubmitting: true, lastAction: ProfileAction.update);
    try {
      final profile = await _repository.updateProfile(
        name: name,
        email: email,
        angkatan: angkatan,
        status: status,
        phone: phone,
        job: job,
      );
      state = state.copyWith(
        profile: profile,
        isSubmitting: false,
        errorMessage: null,
      );
      return true;
    } on DioException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _mapError(error),
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  }) async {
    state = state.copyWith(isSubmitting: true, lastAction: ProfileAction.uploadAvatar);
    try {
      final profile = await _repository.uploadAvatar(bytes: bytes, filename: filename);
      state = state.copyWith(profile: profile, isSubmitting: false, errorMessage: null);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: _mapError(error));
      return false;
    } catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.toString());
      return false;
    }
  }

  String _mapError(DioException error) {
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
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return 'Permintaan gagal (${error.response?.statusCode ?? ''}).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan tidak diketahui.';
    }
  }
}
