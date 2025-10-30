import 'package:flutter/material.dart';
import 'package:forum_alumni/core/constants/app_constants.dart';
import 'package:forum_alumni/features/search/data/models/search_filters.dart';

class SearchFiltersBottomSheet extends StatefulWidget {
  const SearchFiltersBottomSheet({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFiltersChanged;

  @override
  State<SearchFiltersBottomSheet> createState() => _SearchFiltersBottomSheetState();
}

class _SearchFiltersBottomSheetState extends State<SearchFiltersBottomSheet> {
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filter Pencarian',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentFilters = const SearchFilters();
                    });
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          
          // Filters Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Type
                  _buildSectionTitle('Tipe Pencarian'),
                  _buildSearchTypeFilter(),
                  
                  const SizedBox(height: 24),
                  
                  // Sort By
                  _buildSectionTitle('Urutkan Berdasarkan'),
                  _buildSortByFilter(),
                  
                  if (_currentFilters.searchType == SearchType.posts || 
                      _currentFilters.searchType == SearchType.all) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Kategori Postingan'),
                    _buildCategoryFilter(),
                  ],
                  
                  if (_currentFilters.searchType == SearchType.alumni || 
                      _currentFilters.searchType == SearchType.all) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Status Alumni'),
                    _buildAlumniStatusFilter(),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle('Tahun Lulus'),
                    _buildGraduationYearFilter(),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Rentang Tanggal'),
                  _buildDateRangeFilter(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onFiltersChanged(_currentFilters);
                  Navigator.of(context).pop();
                },
                child: const Text('Terapkan Filter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchTypeFilter() {
    return Wrap(
      spacing: 8,
      children: SearchType.values.map((type) {
        final isSelected = _currentFilters.searchType == type;
        return FilterChip(
          label: Text(type.name == 'posts' ? 'Postingan' : 
                      type.name == 'alumni' ? 'Alumni' : 'Semua'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(searchType: type);
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortByFilter() {
    return Column(
      children: SortBy.values.map((sort) {
        return RadioListTile<SortBy>(
          title: Text(sort.name == 'newest' ? 'Terbaru' :
                      sort.name == 'oldest' ? 'Terlama' :
                      sort.name == 'mostLiked' ? 'Paling Disukai' : 'Paling Dikomentari'),
          value: sort,
          groupValue: _currentFilters.sortBy,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _currentFilters = _currentFilters.copyWith(sortBy: value);
              });
            }
          },
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.postCategories.map((category) {
        final isSelected = _currentFilters.category == category;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(
                category: selected ? category : null,
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAlumniStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.alumniStatusOptions.map((status) {
        final isSelected = _currentFilters.alumniStatus == status;
        return FilterChip(
          label: Text(status),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _currentFilters = _currentFilters.copyWith(
                alumniStatus: selected ? status : null,
              );
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildGraduationYearFilter() {
    final currentYear = DateTime.now().year;
    final years = List.generate(20, (index) => currentYear - index);
    
    return DropdownButtonFormField<int>(
      initialValue: _currentFilters.graduationYear,
      decoration: const InputDecoration(
        hintText: 'Pilih tahun lulus',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int>(
          value: null,
          child: Text('Semua tahun'),
        ),
        ...years.map((year) => DropdownMenuItem(
          value: year,
          child: Text(year.toString()),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(graduationYear: value);
        });
      },
    );
  }

  Widget _buildDateRangeFilter() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.date_range),
      title: Text(
        _currentFilters.dateRange != null 
          ? '${_formatDate(_currentFilters.dateRange!.start)} - ${_formatDate(_currentFilters.dateRange!.end)}'
          : 'Pilih rentang tanggal',
      ),
      trailing: _currentFilters.dateRange != null 
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _currentFilters = _currentFilters.copyWith(dateRange: null);
              });
            },
          )
        : const Icon(Icons.chevron_right),
      onTap: _selectDateRange,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _currentFilters.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _currentFilters = _currentFilters.copyWith(dateRange: dateRange);
      });
    }
  }
}
