import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forum_alumni/core/constants/app_constants.dart';
import 'package:forum_alumni/core/presentation/widgets/custom_text_field.dart';
import 'package:forum_alumni/features/forum/presentation/widgets/post_card.dart';
import 'package:forum_alumni/features/search/application/search_controller.dart';
import 'package:forum_alumni/features/search/presentation/widgets/search_filters_bottom_sheet.dart';
import 'package:forum_alumni/features/search/presentation/widgets/alumni_search_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static const String routeName = 'search';
  static const String routePath = '/search';

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  late final TabController _tabController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            color: theme.cardColor,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _searchController,
                        hintText: 'Cari postingan, alumni...',
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchControllerProvider.notifier).clearSearch();
                                },
                              )
                            : null,
                        onChanged: (value) {
                          setState(() {});
                          if (value.length >= 2) {
                            ref.read(searchControllerProvider.notifier).getSuggestions(value);
                          }
                        },
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            ref.read(searchControllerProvider.notifier).search(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showFilters,
                      icon: Icon(
                        Icons.tune,
                        color: theme.colorScheme.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Search suggestions
                if (searchState.suggestions.isNotEmpty && _searchController.text.length >= 2)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: searchState.suggestions.length.clamp(0, 5),
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = searchState.suggestions[index];
                        return ListTile(
                          leading: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          title: Text(suggestion),
                          onTap: () {
                            _searchController.text = suggestion;
                            ref.read(searchControllerProvider.notifier).search(suggestion);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Search Results
          if (searchState.query.isNotEmpty) ...[
            // Search Stats and Tabs
            Container(
              color: theme.cardColor,
              child: Column(
                children: [
                  if (searchState.counts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                      child: Row(
                        children: [
                          Text(
                            'Ditemukan ${searchState.counts['total'] ?? 0} hasil',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text: 'Semua (${searchState.counts['total'] ?? 0})',
                      ),
                      Tab(
                        text: 'Postingan (${searchState.counts['posts'] ?? 0})',
                      ),
                      Tab(
                        text: 'Alumni (${searchState.counts['alumni'] ?? 0})',
                      ),
                    ],
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllResultsTab(searchState),
                  _buildPostsTab(searchState),
                  _buildAlumniTab(searchState),
                ],
              ),
            ),
          ] else
            // Empty State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cari postingan atau alumni',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Masukkan kata kunci untuk memulai pencarian',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllResultsTab(SearchState searchState) {
    if (searchState.isLoading && searchState.posts.isEmpty && searchState.alumni.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              searchState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    final hasResults = searchState.posts.isNotEmpty || searchState.alumni.isNotEmpty;
    
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil ditemukan',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau ubah filter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        if (searchState.posts.isNotEmpty) ...[
          Text(
            'Postingan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...searchState.posts.map((post) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PostCard(
              post: post,
              onTap: () => context.push('/posts/${post.id}'),
              onLikeTap: () {
                // TODO: Implement like functionality
              },
              onCommentTap: () => context.push('/posts/${post.id}'),
              onShareTap: () {
                // TODO: Implement share functionality
              },
            ),
          )),
        ],
        
        if (searchState.alumni.isNotEmpty) ...[
          if (searchState.posts.isNotEmpty) const SizedBox(height: 24),
          Text(
            'Alumni',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...searchState.alumni.map((alumni) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AlumniSearchTile(alumni: alumni),
          )),
        ],
        
        if (searchState.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPostsTab(SearchState searchState) {
    if (searchState.isLoading && searchState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return Center(child: Text(searchState.error!));
    }

    if (searchState.posts.isEmpty) {
      return const Center(child: Text('Tidak ada postingan ditemukan'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: searchState.posts.length + (searchState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= searchState.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final post = searchState.posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PostCard(
            post: post,
            onTap: () => context.push('/posts/${post.id}'),
            onLikeTap: () {
              // TODO: Implement like functionality
            },
            onCommentTap: () => context.push('/posts/${post.id}'),
            onShareTap: () {
              // TODO: Implement share functionality
            },
          ),
        );
      },
    );
  }

  Widget _buildAlumniTab(SearchState searchState) {
    if (searchState.isLoading && searchState.alumni.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return Center(child: Text(searchState.error!));
    }

    if (searchState.alumni.isEmpty) {
      return const Center(child: Text('Tidak ada alumni ditemukan'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: searchState.alumni.length + (searchState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= searchState.alumni.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final alumni = searchState.alumni[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AlumniSearchTile(alumni: alumni),
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFiltersBottomSheet(
        filters: ref.read(searchControllerProvider).filters,
        onFiltersChanged: (filters) {
          ref.read(searchControllerProvider.notifier).updateFilters(filters);
        },
      ),
    );
  }
}
