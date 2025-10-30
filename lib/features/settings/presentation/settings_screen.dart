import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/core/constants/app_constants.dart';
import 'package:forum_alumni/core/providers/theme_provider.dart';
import 'package:forum_alumni/core/services/local_storage_service.dart';
import 'package:forum_alumni/core/services/connectivity_service.dart';
import 'package:forum_alumni/features/export/presentation/export_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const String routeName = 'settings';
  static const String routePath = '/settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Map<String, int>? _cacheInfo;
  List<Map<String, dynamic>>? _pendingActions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final cacheInfo = await LocalStorageService.getCacheInfo();
      final pendingActions = await LocalStorageService.getPendingActions();
      
      setState(() {
        _cacheInfo = cacheInfo;
        _pendingActions = pendingActions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectivity = ref.watch(connectivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _loadCacheInfo,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // Connection Status
            _buildConnectionStatusCard(connectivity),
            
            const SizedBox(height: 16),
            
            // Theme Settings
            _buildThemeSection(),
            
            const SizedBox(height: 16),
            
            // Data Management
            _buildDataManagementSection(),
            
            const SizedBox(height: 16),
            
            // Export Settings
            _buildExportSection(),
            
            const SizedBox(height: 16),
            
            // App Information
            _buildAppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(AsyncValue<bool> connectivity) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Koneksi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            connectivity.when(
              data: (isConnected) => Row(
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Online' : 'Offline',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Memeriksa koneksi...'),
                ],
              ),
              error: (_, __) => const Row(
                children: [
                  Icon(Icons.error, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Status tidak diketahui'),
                ],
              ),
            ),
            if (_pendingActions != null && _pendingActions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_pendingActions!.length} aksi menunggu sinkronisasi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tampilan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final currentTheme = ref.watch(themeNotifierProvider);
                final themeNotifier = ref.read(themeNotifierProvider.notifier);
                
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Terang'),
                      subtitle: const Text('Selalu gunakan tema terang'),
                      value: ThemeMode.light,
                      groupValue: currentTheme,
                      onChanged: (ThemeMode? value) {
                        if (value != null) themeNotifier.setTheme(value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Gelap'),
                      subtitle: const Text('Selalu gunakan tema gelap'),
                      value: ThemeMode.dark,
                      groupValue: currentTheme,
                      onChanged: (ThemeMode? value) {
                        if (value != null) themeNotifier.setTheme(value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Sistem'),
                      subtitle: const Text('Ikuti pengaturan sistem'),
                      value: ThemeMode.system,
                      groupValue: currentTheme,
                      onChanged: (ThemeMode? value) {
                        if (value != null) themeNotifier.setTheme(value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manajemen Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_cacheInfo != null) ...[
              _buildCacheInfoTile('Total Cache', '${(_cacheInfo!['total']! / 1024).toStringAsFixed(1)} KB'),
              _buildCacheInfoTile('Posts Cache', '${(_cacheInfo!['posts']! / 1024).toStringAsFixed(1)} KB'),
              _buildCacheInfoTile('Alumni Cache', '${(_cacheInfo!['alumni']! / 1024).toStringAsFixed(1)} KB'),
              _buildCacheInfoTile('Notifications Cache', '${(_cacheInfo!['notifications']! / 1024).toStringAsFixed(1)} KB'),
              
              const Divider(),
              
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('Hapus Cache'),
                subtitle: const Text('Hapus semua data yang disimpan offline'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: _showClearCacheDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheInfoTile(String title, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Posts'),
              subtitle: const Text('Export data postingan ke file'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pushNamed(context, ExportScreen.routePath);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Aplikasi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoTile('Nama Aplikasi', AppConstants.appName),
            _buildInfoTile('Versi', AppConstants.appVersion),
            _buildInfoTile('Developer', 'Forum Alumni Team'),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: _showAboutDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Cache'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua data cache? '
            'Data yang disimpan offline akan hilang dan Anda memerlukan koneksi internet untuk memuat ulang data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearCache();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    try {
      await LocalStorageService.clearAllCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadCacheInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.school,
          color: Colors.white,
          size: 24,
        ),
      ),
      children: [
        const Text(
          'Forum Alumni adalah aplikasi untuk menghubungkan alumni '
          'dan memfasilitasi komunikasi antar sesama alumni.',
        ),
      ],
    );
  }
}
