import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/features/admin/data/admin_repository.dart';
import 'package:forum_alumni/features/admin/data/models/admin_alumni.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final adminNotifierProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminNotifier(repository);
});

enum AdminStatus { initial, loading, loaded, error }

enum ModerationAction { approve, reject, deletePost, deleteComment }

class AdminState extends Equatable {
  const AdminState({
    this.status = AdminStatus.initial,
    this.pendingAlumni = const [],
    this.errorMessage,
    this.isProcessing = false,
    this.lastAction,
  });

  final AdminStatus status;
  final List<AdminAlumni> pendingAlumni;
  final String? errorMessage;
  final bool isProcessing;
  final ModerationAction? lastAction;

  bool get isLoading => status == AdminStatus.loading;

  AdminState copyWith({
    AdminStatus? status,
    List<AdminAlumni>? pendingAlumni,
    String? errorMessage,
    bool? isProcessing,
    ModerationAction? lastAction,
  }) {
    return AdminState(
      status: status ?? this.status,
      pendingAlumni: pendingAlumni ?? this.pendingAlumni,
      errorMessage: errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      lastAction: lastAction,
    );
  }

  @override
  List<Object?> get props => [status, pendingAlumni, errorMessage, isProcessing, lastAction];
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier(this._repository) : super(const AdminState()) {
    unawaited(loadPendingAlumni());
  }

  final AdminRepository _repository;

  Future<void> loadPendingAlumni() async {
    state = state.copyWith(status: AdminStatus.loading, errorMessage: null);
    try {
      final data = await _repository.fetchPendingAlumni();
      state = state.copyWith(
        status: AdminStatus.loaded,
        pendingAlumni: data,
        errorMessage: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        status: AdminStatus.error,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        status: AdminStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> verifyAlumni(AdminAlumni alumni, {required bool approved}) async {
    state = state.copyWith(isProcessing: true, lastAction: approved ? ModerationAction.approve : ModerationAction.reject);
    try {
      await _repository.verifyAlumni(alumniId: alumni.id, approved: approved);
      final updated = state.pendingAlumni.where((item) => item.id != alumni.id).toList();
      state = state.copyWith(
        pendingAlumni: updated,
        isProcessing: false,
        errorMessage: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<bool> deletePost(int postId) async {
    state = state.copyWith(isProcessing: true, lastAction: ModerationAction.deletePost);
    try {
      await _repository.deletePost(postId);
      state = state.copyWith(isProcessing: false, errorMessage: null);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(isProcessing: false, errorMessage: _mapError(error));
      return false;
    } catch (error) {
      state = state.copyWith(isProcessing: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> deleteComment(int commentId) async {
    state = state.copyWith(isProcessing: true, lastAction: ModerationAction.deleteComment);
    try {
      await _repository.deleteComment(commentId);
      state = state.copyWith(isProcessing: false, errorMessage: null);
      return true;
    } on DioException catch (error) {
      state = state.copyWith(isProcessing: false, errorMessage: _mapError(error));
      return false;
    } catch (error) {
      state = state.copyWith(isProcessing: false, errorMessage: error.toString());
      return false;
    }
  }

  String _mapError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> data = error.response!.data as Map<String, dynamic>;
      if (data['message'] is String) {
        return data['message'] as String;
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
