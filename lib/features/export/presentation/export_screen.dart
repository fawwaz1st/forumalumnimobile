import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/core/constants/app_constants.dart';
import 'package:forum_alumni/core/presentation/widgets/custom_button.dart';
import 'package:forum_alumni/features/export/application/export_controller.dart';
import 'package:forum_alumni/features/export/data/export_repository.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  static const String routeName = 'export';
  static const String routePath = '/export';

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.json;
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  int? _postLimit = 100;
  bool _exportMyPostsOnly = false;

  @override
  void initState() {
    super.initState();
    // Load export stats when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exportControllerProvider.notifier).loadExportStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Stats Card
            if (exportState.stats != null) _buildStatsCard(exportState.stats!),
            
            const SizedBox(height: 24),
            
            // Export Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Options',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Format Selection
                    Text(
                      'Export Format',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ExportFormat.values.map((format) {
                        return FilterChip(
                          label: Text(_getFormatLabel(format)),
                          selected: _selectedFormat == format,
                          onSelected: format != ExportFormat.pdf ? (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFormat = format;
                              });
                            }
                          } : null,
                          avatar: format == ExportFormat.pdf 
                            ? Icon(Icons.lock, size: 16, color: theme.disabledColor)
                            : null,
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // My Posts Only Toggle
                    SwitchListTile(
                      title: const Text('Export My Posts Only'),
                      subtitle: const Text('Only export posts created by you'),
                      value: _exportMyPostsOnly,
                      onChanged: (value) {
                        setState(() {
                          _exportMyPostsOnly = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const Divider(),
                    
                    // Category Filter
                    Text(
                      'Category Filter',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        hintText: 'All categories',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...AppConstants.postCategories.map((category) =>
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date Range Filter
                    Text(
                      'Date Range',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDateRange,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDateRange != null
                                ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                                : 'Select date range (optional)',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Icon(Icons.date_range),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_selectedDateRange != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear date range'),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Post Limit
                    Text(
                      'Post Limit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: _postLimit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No limit'),
                        ),
                        DropdownMenuItem(value: 50, child: Text('50 posts')),
                        DropdownMenuItem(value: 100, child: Text('100 posts')),
                        DropdownMenuItem(value: 500, child: Text('500 posts')),
                        DropdownMenuItem(value: 1000, child: Text('1000 posts')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _postLimit = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Export Progress
            if (exportState.isExporting) _buildExportProgress(exportState),
            
            // Export Result
            if (exportState.exportedFilePath != null) _buildExportResult(exportState),
            
            // Error Display
            if (exportState.error != null) _buildErrorCard(exportState.error!),
            
            const SizedBox(height: 24),
            
            // Export Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: exportState.isExporting ? 'Exporting...' : 'Start Export',
                onPressed: exportState.isExporting ? null : _startExport,
                type: CustomButtonType.filled,
                isLoading: exportState.isExporting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Posts',
                    stats['total_posts']?.toString() ?? '0',
                    Icons.article,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Users',
                    stats['total_users']?.toString() ?? '0',
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Categories: ${(stats['categories'] as List?)?.join(', ') ?? 'N/A'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExportProgress(ExportState exportState) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporting...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: exportState.exportProgress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '${(exportState.exportProgress * 100).toInt()}% complete',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportResult(ExportState exportState) {
    final theme = Theme.of(context);
    final fileName = exportState.exportedFilePath!.split('/').last;
    
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export Completed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'File: $fileName',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Posts exported: ${exportState.posts.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(exportControllerProvider.notifier).shareExportedFile();
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(exportControllerProvider.notifier).clearExport();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Export'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Export Failed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ref.read(exportControllerProvider.notifier).clearError();
              },
              icon: const Icon(Icons.close),
              label: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.pdf:
        return 'PDF (Coming Soon)';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateRange = dateRange;
      });
    }
  }

  void _startExport() {
    ref.read(exportControllerProvider.notifier).exportPosts(
      format: _selectedFormat,
      userId: _exportMyPostsOnly ? 'current_user' : null, // TODO: Get actual user ID
      category: _selectedCategory,
      fromDate: _selectedDateRange?.start,
      toDate: _selectedDateRange?.end,
      limit: _postLimit,
    );
  }
}
