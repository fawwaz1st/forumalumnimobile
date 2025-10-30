import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forum_alumni/features/notifications/data/models/notification_model.dart';
import 'package:forum_alumni/features/notifications/data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository();
});

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return NotificationsNotifier(repository);
});

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentPage = 0,
    this.hasMore = true,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int currentPage;
  final bool hasMore;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isLoading => status == NotificationsStatus.loading;
  bool get isInitial => status == NotificationsStatus.initial;
  bool get isLoaded => status == NotificationsStatus.loaded;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? currentPage,
    bool? hasMore,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        currentPage,
        hasMore,
        isRefreshing,
        isLoadingMore,
        errorMessage,
      ];
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._repository) : super(const NotificationsState()) {
    unawaited(fetchInitial());
  }

  final NotificationsRepository _repository;

  Future<void> fetchInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(
      status: NotificationsStatus.loading,
      errorMessage: null,
    );

    try {
      final notifications = await _repository.getNotifications(page: 1);
      final unreadCount = await _repository.getUnreadCount();
      
      state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
        currentPage: 1,
        hasMore: notifications.length >= 20,
        errorMessage: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing || state.isLoading) return;
    
    state = state.copyWith(isRefreshing: true, errorMessage: null);
    
    try {
      final notifications = await _repository.getNotifications(page: 1);
      final unreadCount = await _repository.getUnreadCount();
      
      state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
        unreadCount: unreadCount,
        currentPage: 1,
        hasMore: notifications.length >= 20,
        isRefreshing: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading || state.isRefreshing) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final nextPage = state.currentPage + 1;
      final newNotifications = await _repository.getNotifications(page: nextPage);
      final updatedNotifications = List<NotificationModel>.from(state.notifications)
        ..addAll(newNotifications);

      state = state.copyWith(
        notifications: updatedNotifications,
        currentPage: nextPage,
        hasMore: newNotifications.length >= 20,
        isLoadingMore: false,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: _mapError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (error) {
      // Silently fail for UX, could show snackbar if needed
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal menandai semua notifikasi sebagai sudah dibaca');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (error) {
      state = state.copyWith(errorMessage: 'Gagal menghapus notifikasi');
    }
  }

  String _mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Sesi Anda telah berakhir. Silakan login kembali.';
        } else if (statusCode == 403) {
          return 'Anda tidak memiliki akses untuk melihat notifikasi.';
        } else if (statusCode == 500) {
          return 'Terjadi kesalahan pada server. Coba lagi nanti.';
        }
        return 'Terjadi kesalahan: ${error.response?.statusMessage ?? "Unknown error"}';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      default:
        return 'Terjadi kesalahan yang tidak dikenal.';
    }
  }
}
