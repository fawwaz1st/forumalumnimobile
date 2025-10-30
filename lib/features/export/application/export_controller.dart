import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forum_alumni/features/export/data/export_repository.dart';
import 'package:forum_alumni/features/forum/data/models/post_model.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepository();
});

final exportControllerProvider = StateNotifierProvider<ExportController, ExportState>((ref) {
  return ExportController(ref.read(exportRepositoryProvider));
});

class ExportState {
  const ExportState({
    this.isExporting = false,
    this.exportProgress = 0.0,
    this.exportedFilePath,
    this.error,
    this.stats,
    this.posts = const [],
  });

  final bool isExporting;
  final double exportProgress;
  final String? exportedFilePath;
  final String? error;
  final Map<String, dynamic>? stats;
  final List<PostModel> posts;

  ExportState copyWith({
    bool? isExporting,
    double? exportProgress,
    String? exportedFilePath,
    String? error,
    Map<String, dynamic>? stats,
    List<PostModel>? posts,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      exportProgress: exportProgress ?? this.exportProgress,
      exportedFilePath: exportedFilePath,
      error: error,
      stats: stats ?? this.stats,
      posts: posts ?? this.posts,
    );
  }
}

class ExportController extends StateNotifier<ExportState> {
  ExportController(this._repository) : super(const ExportState());

  final ExportRepository _repository;

  Future<void> loadExportStats() async {
    try {
      final stats = await _repository.getExportStats();
      state = state.copyWith(stats: stats);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load export stats: ${e.toString()}');
    }
  }

  Future<void> loadUserPosts(String userId) async {
    state = state.copyWith(isExporting: true, error: null, exportProgress: 0.1);
    
    try {
      final posts = await _repository.getUserPosts(userId);
      state = state.copyWith(
        posts: posts,
        exportProgress: 0.3,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to load user posts: ${e.toString()}',
      );
    }
  }

  Future<void> exportPosts({
    required ExportFormat format,
    String? userId,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    state = state.copyWith(
      isExporting: true,
      error: null,
      exportedFilePath: null,
      exportProgress: 0.0,
    );

    try {
      // Load posts if not already loaded
      List<PostModel> postsToExport;
      if (userId != null) {
        state = state.copyWith(exportProgress: 0.2);
        postsToExport = await _repository.getUserPosts(userId);
      } else {
        state = state.copyWith(exportProgress: 0.2);
        postsToExport = await _repository.getAllPosts(
          limit: limit,
          category: category,
          fromDate: fromDate,
          toDate: toDate,
        );
      }

      state = state.copyWith(exportProgress: 0.5);

      String filePath;
      switch (format) {
        case ExportFormat.json:
          filePath = await _repository.exportToJson(postsToExport);
          break;
        case ExportFormat.csv:
          filePath = await _repository.exportToCsv(postsToExport);
          break;
        case ExportFormat.pdf:
          throw UnimplementedError('PDF export not yet implemented');
      }

      state = state.copyWith(
        isExporting: false,
        exportProgress: 1.0,
        exportedFilePath: filePath,
        posts: postsToExport,
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Export failed: ${e.toString()}',
      );
    }
  }

  Future<void> shareExportedFile() async {
    if (state.exportedFilePath == null) return;

    try {
      await _repository.shareFile(state.exportedFilePath!);
    } catch (e) {
      state = state.copyWith(error: 'Failed to share file: ${e.toString()}');
    }
  }

  void clearExport() {
    state = const ExportState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
