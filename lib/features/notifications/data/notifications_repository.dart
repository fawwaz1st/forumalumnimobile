import 'package:dio/dio.dart';
import 'package:forum_alumni/core/services/api_client.dart';
import 'package:forum_alumni/features/notifications/data/models/notification_model.dart';

class NotificationsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.client.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to fetch notifications: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.client.get('/notifications/unread-count');
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw Exception('Failed to fetch unread count: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.client.post('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw Exception('Failed to mark notification as read: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.client.post('/notifications/mark-all-read');
    } on DioException catch (e) {
      throw Exception('Failed to mark all notifications as read: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiClient.client.delete('/notifications/$notificationId');
    } on DioException catch (e) {
      throw Exception('Failed to delete notification: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> updatePushToken(String token) async {
    try {
      await _apiClient.client.post('/notifications/push-token', data: {
        'token': token,
      });
    } on DioException catch (e) {
      throw Exception('Failed to update push token: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
