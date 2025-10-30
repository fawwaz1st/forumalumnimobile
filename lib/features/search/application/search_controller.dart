import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forum_alumni/features/forum/data/models/post_model.dart';
import 'package:forum_alumni/features/search/data/models/search_filters.dart';
import 'package:forum_alumni/features/search/data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});

final searchControllerProvider = StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController(ref.read(searchRepositoryProvider));
});

class SearchState {
  const SearchState({
    this.query = '',
    this.filters = const SearchFilters(),
    this.posts = const [],
    this.alumni = const [],
    this.suggestions = const [],
    this.counts = const {},
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
  });

  final String query;
  final SearchFilters filters;
  final List<PostModel> posts;
  final List<Map<String, dynamic>> alumni;
  final List<String> suggestions;
  final Map<String, int> counts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    List<PostModel>? posts,
    List<Map<String, dynamic>>? alumni,
    List<String>? suggestions,
    Map<String, int>? counts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      posts: posts ?? this.posts,
      alumni: alumni ?? this.alumni,
      suggestions: suggestions ?? this.suggestions,
      counts: counts ?? this.counts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._repository) : super(const SearchState());

  final SearchRepository _repository;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
      error: null,
      currentPage: 1,
    );

    try {
      final results = await _searchBasedOnType(query, state.filters, 1);
      final counts = await _repository.getSearchCounts(query);

      final resultPosts = results['posts'] as List<PostModel>? ?? <PostModel>[];
      final resultAlumni = results['alumni'] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];
      
      state = state.copyWith(
        posts: resultPosts,
        alumni: resultAlumni,
        counts: counts,
        isLoading: false,
        hasMore: resultPosts.length + resultAlumni.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal melakukan pencarian: ${e.toString()}',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.query.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final results = await _searchBasedOnType(state.query, state.filters, nextPage);

      final resultPosts = results['posts'] as List<PostModel>? ?? <PostModel>[];
      final resultAlumni = results['alumni'] as List<Map<String, dynamic>>? ?? <Map<String, dynamic>>[];
      
      final List<PostModel> newPosts = [
        ...state.posts,
        ...resultPosts,
      ];
      
      final List<Map<String, dynamic>> newAlumni = [
        ...state.alumni,
        ...resultAlumni,
      ];

      state = state.copyWith(
        posts: newPosts,
        alumni: newAlumni,
        currentPage: nextPage,
        isLoading: false,
        hasMore: resultPosts.length + resultAlumni.length >= 10,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat lebih banyak hasil: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> _searchBasedOnType(
    String query,
    SearchFilters filters,
    int page,
  ) async {
    switch (filters.searchType) {
      case SearchType.posts:
        final posts = await _repository.searchPosts(
          query: query,
          filters: filters,
          page: page,
        );
        return {'posts': posts, 'alumni': <Map<String, dynamic>>[]};

      case SearchType.alumni:
        final alumni = await _repository.searchAlumni(
          query: query,
          filters: filters,
          page: page,
        );
        return {'posts': <PostModel>[], 'alumni': alumni};

      case SearchType.all:
        return await _repository.searchAll(
          query: query,
          filters: filters,
          page: page,
        );
    }
  }

  Future<void> getSuggestions(String query) async {
    if (query.length < 2) {
      state = state.copyWith(suggestions: []);
      return;
    }

    try {
      final suggestions = await _repository.getSearchSuggestions(query);
      state = state.copyWith(suggestions: suggestions);
    } catch (e) {
      // Ignore suggestions errors
      state = state.copyWith(suggestions: []);
    }
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void clearSearch() {
    state = const SearchState();
  }
}
