import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/settings_controller.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tema', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Sistem')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Terang')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Gelap')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (v) => notifier.setThemeMode(v.first),
          ),
          const SizedBox(height: 24),

          Text('Preferensi Notifikasi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...['comments', 'mentions', 'votes', 'follows'].map((k) {
            return SwitchListTile(
              title: Text(_labelFor(k)),
              value: settings.notifPrefs[k] ?? true,
              onChanged: (val) => notifier.setNotifPref(k, val),
            );
          }),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Kelola Izin Notifikasi'),
            subtitle: const Text('Minta izin sistem untuk menerima push / notifikasi lokal'),
            onTap: () => context.push('/notifications'),
          ),

          const Divider(height: 32),

          Text('Penggunaan Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Muat gambar saat pakai jaringan seluler'),
            value: settings.loadImagesOnCellular,
            onChanged: notifier.setLoadImagesOnCellular,
          ),

          const Divider(height: 32),

          Text('Data App', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Bersihkan Cache'),
            onTap: () async {
              await notifier.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache dibersihkan')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Ekspor Data (JSON)'),
            onTap: () async {
              final dir = await getApplicationDocumentsDirectory();
              final file = File('${dir.path}/forum_alumni_export.json');
              final map = {
                'settings': settings.toMap(),
              };
              await file.writeAsString(const JsonEncoder.withIndent('  ').convert(map));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Diekspor ke: ${file.path}')));
              }
            },
          ),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            onTap: () async {
              final info = await PackageInfo.fromPlatform();
              if (context.mounted) {
                showAboutDialog(
                  context: context,
                  applicationName: info.appName,
                  applicationVersion: '${info.version}+${info.buildNumber}',
                  applicationIcon: const FlutterLogo(),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Lisensi'),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case 'comments':
        return 'Komentar & Balasan';
      case 'mentions':
        return 'Mention';
      case 'votes':
        return 'Voting';
      case 'follows':
        return 'Mengikuti';
      default:
        return key;
    }
  }
}
