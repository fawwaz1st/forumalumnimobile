import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../posts/data/posts_repository.dart';
import '../../posts/models/post.dart';

class SearchFilters {
  final String query;
  final DateTime? from;
  final DateTime? to;
  final String? author;
  final List<String> categories; // category ids
  final String sort; // relevance | date | votes

  const SearchFilters({
    this.query = '',
    this.from,
    this.to,
    this.author,
    this.categories = const [],
    this.sort = 'relevance',
  });

  SearchFilters copyWith({
    String? query,
    DateTime? from,
    DateTime? to,
    String? author,
    List<String>? categories,
    String? sort,
  }) => SearchFilters(
        query: query ?? this.query,
        from: from ?? this.from,
        to: to ?? this.to,
        author: author ?? this.author,
        categories: categories ?? this.categories,
        sort: sort ?? this.sort,
      );
}

class SearchState {
  final SearchFilters filters;
  final List<Post> results;
  final bool loading;
  final List<String> history;

  const SearchState({
    this.filters = const SearchFilters(),
    this.results = const [],
    this.loading = false,
    this.history = const [],
  });

  SearchState copyWith({SearchFilters? filters, List<Post>? results, bool? loading, List<String>? history}) =>
      SearchState(
        filters: filters ?? this.filters,
        results: results ?? this.results,
        loading: loading ?? this.loading,
        history: history ?? this.history,
      );
}

class AdvancedSearchController extends StateNotifier<SearchState> {
  AdvancedSearchController(this.ref) : super(const SearchState()) {
    _loadHistory();
  }
  final Ref ref;

  Future<void> _loadHistory() async {
    final box = await _historyBox;
    final list = (box.get('q') as List?)?.cast<String>() ?? const [];
    state = state.copyWith(history: list);
  }

  Future<Box> get _historyBox async => Hive.isBoxOpen('search_history_v1')
      ? Hive.box('search_history_v1')
      : await Hive.openBox('search_history_v1');

  Future<void> clearHistory() async {
    final box = await _historyBox;
    await box.put('q', <String>[]);
    state = state.copyWith(history: const []);
  }

  Future<void> addHistory(String q) async {
    final box = await _historyBox;
    final list = (box.get('q') as List?)?.cast<String>() ?? <String>[];
    if (q.trim().isEmpty) return;
    list.remove(q);
    list.insert(0, q);
    await box.put('q', list.take(15).toList());
    state = state.copyWith(history: list);
  }

  Future<void> search() async {
    final repo = ref.read(postsRepositoryProvider);
    state = state.copyWith(loading: true);
    try {
      // Ambil beberapa halaman & filter di sisi klien (mock)
      final f = state.filters;
      List<Post> all = [];
      for (var page = 1; page <= 3; page++) {
        final items = await repo.fetchPosts(page: page, limit: 20, query: f.query, categoryId: null);
        if (items.isEmpty) break;
        all.addAll(items);
      }
      // Filter tambahan
      if (f.author != null && f.author!.isNotEmpty) {
        all = all.where((p) => p.author.name.toLowerCase().contains(f.author!.toLowerCase()) || p.author.email.toLowerCase().contains(f.author!.toLowerCase())).toList();
      }
      if (f.categories.isNotEmpty) {
        all = all.where((p) => p.category != null && f.categories.contains(p.category!.id)).toList();
      }
      if (f.from != null) {
        all = all.where((p) => p.createdAt.isAfter(f.from!)).toList();
      }
      if (f.to != null) {
        all = all.where((p) => p.createdAt.isBefore(f.to!)).toList();
      }
      switch (f.sort) {
        case 'date':
          all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'votes':
          all.sort((a, b) => b.votes.compareTo(a.votes));
          break;
        default: // relevance (very naive)
          all.sort((a, b) => b.votes.compareTo(a.votes));
      }
      state = state.copyWith(results: all, loading: false);
      unawaited(addHistory(f.query));
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  void setFilters(SearchFilters f) {
    state = state.copyWith(filters: f);
  }
}

final searchControllerProvider = StateNotifierProvider<AdvancedSearchController, SearchState>((ref) => AdvancedSearchController(ref));
