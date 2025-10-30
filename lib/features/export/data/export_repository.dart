import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:forum_alumni/core/services/api_client.dart';
import 'package:forum_alumni/features/forum/data/models/post_model.dart';

enum ExportFormat { json, csv, pdf }

class ExportRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<PostModel>> getUserPosts(String userId) async {
    try {
      final response = await _apiClient.client.get('/users/$userId/posts');
      final List<dynamic> postsData = response.data['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }

  Future<List<PostModel>> getAllPosts({
    int? limit,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (category != null) queryParams['category'] = category;
      if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

      final response = await _apiClient.client.get(
        '/posts/export',
        queryParameters: queryParams,
      );
      
      final List<dynamic> postsData = response.data['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch posts for export: $e');
    }
  }

  Future<String> exportToJson(List<PostModel> posts) async {
    try {
      final jsonData = posts.map((post) => post.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exported_at': DateTime.now().toIso8601String(),
        'total_posts': posts.length,
        'posts': jsonData,
      });

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'forum_posts_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export to JSON: $e');
    }
  }

  Future<String> exportToCsv(List<PostModel> posts) async {
    try {
      final headers = [
        'ID',
        'Content',
        'Author',
        'Media Type',
        'Likes Count',
        'Comments Count',
        'Created At',
      ];

      final rows = posts.map((post) => [
        post.id.toString(),
        post.content.replaceAll('\n', ' ').replaceAll('\r', ''),
        post.author.name,
        post.mediaType ?? 'text',
        post.likesCount.toString(),
        post.commentsCount.toString(),
        post.createdAt.toIso8601String(),
      ]).toList();

      final csvData = [headers, ...rows];
      final csvString = _convertToCsv(csvData);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'forum_posts_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvString);
      return file.path;
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  String _convertToCsv(List<List<String>> data) {
    return data.map((row) {
      return row.map((field) {
        // Escape quotes and wrap in quotes if necessary
        if (field.contains('"') || field.contains(',') || field.contains('\n')) {
          return '"${field.replaceAll('"', '""')}"';
        }
        return field;
      }).join(',');
    }).join('\n');
  }

  Future<void> shareFile(String filePath) async {
    try {
      // Note: Share functionality would require share_plus package
      // For now, we'll just throw an unimplemented error
      throw UnimplementedError('Share functionality not implemented yet');
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  Future<Map<String, dynamic>> getExportStats() async {
    try {
      final response = await _apiClient.client.get('/export/stats');
      return response.data['data'];
    } catch (e) {
      return {
        'total_posts': 0,
        'total_users': 0,
        'categories': <String>[],
        'date_range': {
          'earliest': DateTime.now().toIso8601String(),
          'latest': DateTime.now().toIso8601String(),
        },
      };
    }
  }
}
