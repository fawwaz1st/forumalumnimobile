import 'package:forum_alumni/core/services/api_client.dart';
import 'package:forum_alumni/features/forum/data/models/post_model.dart';
import 'package:forum_alumni/features/search/data/models/search_filters.dart';

class SearchRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<PostModel>> searchPosts({
    required String query,
    required SearchFilters filters,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page,
        'limit': limit,
        ...filters.toJson(),
      };

      final response = await _apiClient.client.get(
        '/posts/search',
        queryParameters: queryParams,
      );

      final List<dynamic> postsData = response.data['data'];
      return postsData.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchAlumni({
    required String query,
    required SearchFilters filters,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page,
        'limit': limit,
        ...filters.toJson(),
      };

      final response = await _apiClient.client.get(
        '/alumni_profiles/search',
        queryParameters: queryParams,
      );

      final List<dynamic> alumniData = response.data['data'];
      return alumniData.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to search alumni: $e');
    }
  }

  Future<Map<String, dynamic>> searchAll({
    required String query,
    required SearchFilters filters,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page,
        'limit': limit,
        ...filters.toJson(),
      };

      final response = await _apiClient.client.get(
        '/search',
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      return {
        'posts': (data['posts'] as List?)
                ?.map((json) => PostModel.fromJson(json))
                .toList() ??
            [],
        'alumni': (data['alumni'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      };
    } catch (e) {
      throw Exception('Failed to search all: $e');
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await _apiClient.client.get(
        '/search/suggestions',
        queryParameters: {'q': query},
      );

      final List<dynamic> suggestions = response.data['data'];
      return suggestions.map((item) => item.toString()).toList();
    } catch (e) {
      // Return empty list if suggestions fail
      return [];
    }
  }

  Future<Map<String, int>> getSearchCounts(String query) async {
    try {
      final response = await _apiClient.client.get(
        '/search/count',
        queryParameters: {'q': query},
      );

      final data = response.data['data'];
      return {
        'posts': data['posts'] ?? 0,
        'alumni': data['alumni'] ?? 0,
        'total': data['total'] ?? 0,
      };
    } catch (e) {
      return {'posts': 0, 'alumni': 0, 'total': 0};
    }
  }
}
