import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SortBy {
  newest,
  oldest,
  mostLiked,
  mostCommented,
}

enum SearchType {
  posts,
  alumni,
  all,
}

class SearchFilters extends Equatable {
  const SearchFilters({
    this.sortBy = SortBy.newest,
    this.searchType = SearchType.all,
    this.category,
    this.dateRange,
    this.alumniStatus,
    this.graduationYear,
  });

  final SortBy sortBy;
  final SearchType searchType;
  final String? category;
  final DateTimeRange? dateRange;
  final String? alumniStatus;
  final int? graduationYear;

  SearchFilters copyWith({
    SortBy? sortBy,
    SearchType? searchType,
    String? category,
    DateTimeRange? dateRange,
    String? alumniStatus,
    int? graduationYear,
  }) {
    return SearchFilters(
      sortBy: sortBy ?? this.sortBy,
      searchType: searchType ?? this.searchType,
      category: category ?? this.category,
      dateRange: dateRange ?? this.dateRange,
      alumniStatus: alumniStatus ?? this.alumniStatus,
      graduationYear: graduationYear ?? this.graduationYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sort_by': sortBy.name,
      'search_type': searchType.name,
      if (category != null) 'category': category,
      if (dateRange != null) 'date_from': dateRange!.start.toIso8601String(),
      if (dateRange != null) 'date_to': dateRange!.end.toIso8601String(),
      if (alumniStatus != null) 'alumni_status': alumniStatus,
      if (graduationYear != null) 'graduation_year': graduationYear,
    };
  }

  String get sortByText {
    switch (sortBy) {
      case SortBy.newest:
        return 'Terbaru';
      case SortBy.oldest:
        return 'Terlama';
      case SortBy.mostLiked:
        return 'Paling Disukai';
      case SortBy.mostCommented:
        return 'Paling Dikomentari';
    }
  }

  String get searchTypeText {
    switch (searchType) {
      case SearchType.posts:
        return 'Postingan';
      case SearchType.alumni:
        return 'Alumni';
      case SearchType.all:
        return 'Semua';
    }
  }

  @override
  List<Object?> get props => [
        sortBy,
        searchType,
        category,
        dateRange,
        alumniStatus,
        graduationYear,
      ];
}
