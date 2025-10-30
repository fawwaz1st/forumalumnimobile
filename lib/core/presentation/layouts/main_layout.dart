import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forum_alumni/features/forum/presentation/home_screen.dart';
import 'package:forum_alumni/features/profile/presentation/profile_screen.dart';
import 'package:forum_alumni/features/forum/presentation/create_post_screen.dart';
import 'package:forum_alumni/core/constants/app_constants.dart';
import 'package:forum_alumni/core/providers/theme_provider.dart';
import 'package:forum_alumni/features/export/presentation/export_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<BottomNavigationBarItem> _bottomNavItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications),
      label: 'Notifikasi',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_outlined),
      activeIcon: Icon(Icons.menu),
      label: 'Menu',
    ),
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go(HomeScreen.routePath);
        break;
      case 1:
        context.push('/notifications');
        break;
      case 2:
        context.go(ProfileScreen.routePath);
        break;
      case 3:
        // Show menu bottom sheet
        _showMenuBottomSheet();
        break;
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature akan segera hadir!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMenuBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
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
              
              const SizedBox(height: 24),
              
              // Menu Items
              _MenuTile(
                icon: Icons.search,
                title: 'Pencarian',
                subtitle: 'Cari postingan dan alumni',
                onTap: () {
                  Navigator.pop(context);
                  context.push('/search');
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export Data'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(ExportScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text('Theme: ${ref.watch(themeNotifierProvider.notifier).currentThemeString}'),
                trailing: Icon(ref.watch(themeNotifierProvider.notifier).currentThemeIcon),
                onTap: () {
                  Navigator.pop(context);
                  _showThemeDialog();
                },
              ),
              
              _MenuTile(
                icon: Icons.info_outline,
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi aplikasi',
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              
              _MenuTile(
                icon: Icons.logout,
                title: 'Keluar',
                subtitle: 'Logout dari aplikasi',
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation();
                },
                isDestructive: true,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Tema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final currentTheme = ref.watch(themeNotifierProvider);
                  final themeNotifier = ref.read(themeNotifierProvider.notifier);
                  
                  return Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: const Text('Terang'),
                        subtitle: const Text('Tema terang'),
                        value: ThemeMode.light,
                        groupValue: currentTheme,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeNotifier.setTheme(value);
                          }
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Gelap'),
                        subtitle: const Text('Tema gelap'),
                        value: ThemeMode.dark,
                        groupValue: currentTheme,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeNotifier.setTheme(value);
                          }
                        },
                      ),
                      RadioListTile<ThemeMode>(
                        title: const Text('Sistem'),
                        subtitle: const Text('Ikuti pengaturan sistem'),
                        value: ThemeMode.system,
                        groupValue: currentTheme,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeNotifier.setTheme(value);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
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
          'Aplikasi Forum Alumni untuk menghubungkan sesama alumni dan berbagi informasi terkini.',
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                // TODO: Implement logout logic
                _showComingSoon('Logout');
              },
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    
    // Update current index based on current route
    if (location.startsWith(HomeScreen.routePath)) {
      _currentIndex = 0;
    } else if (location.startsWith(ProfileScreen.routePath)) {
      _currentIndex = 2;
    }

    return Scaffold(
      body: widget.child,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                context.push(CreatePostScreen.routePath);
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        items: _bottomNavItems,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color ?? theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: (color ?? theme.colorScheme.onSurface).withOpacity(0.7),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
