import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forum_alumni/features/admin/application/admin_controller.dart';
import 'package:forum_alumni/features/auth/application/auth_controller.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  static const String routeName = 'admin-dashboard';
  static const String routePath = '/admin';

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final adminState = ref.watch(adminNotifierProvider);

    // Check if user is admin
    if (authState.user?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Akses Ditolak')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 72, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Anda tidak memiliki akses ke halaman ini',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    ref.listen<AdminState>(adminNotifierProvider, (previous, next) {
      if (!mounted) return;
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people_alt),
              text: 'Verifikasi Alumni',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Moderasi Konten',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(adminNotifierProvider.notifier).loadPendingAlumni(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlumniVerificationTab(adminState),
          _buildContentModerationTab(),
        ],
      ),
    );
  }

  Widget _buildAlumniVerificationTab(AdminState adminState) {
    if (adminState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminState.pendingAlumni.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Tidak ada alumni yang menunggu verifikasi',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: adminState.pendingAlumni.length,
      itemBuilder: (context, index) {
        final alumni = adminState.pendingAlumni[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: alumni.avatarUrl != null
                          ? NetworkImage(alumni.avatarUrl!)
                          : null,
                      child: alumni.avatarUrl == null
                          ? Text(alumni.name.isNotEmpty ? alumni.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alumni.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            alumni.email,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(alumni.status.toUpperCase()),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (alumni.angkatan.isNotEmpty)
                  _buildInfoRow(Icons.school, 'Angkatan', alumni.angkatan),
                if (alumni.phone != null)
                  _buildInfoRow(Icons.phone, 'No. HP', alumni.phone!),
                if (alumni.job != null)
                  _buildInfoRow(Icons.work, 'Pekerjaan', alumni.job!),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: adminState.isProcessing
                            ? null
                            : () => _showRejectDialog(alumni),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: adminState.isProcessing
                            ? null
                            : () => ref
                                .read(adminNotifierProvider.notifier)
                                .verifyAlumni(alumni, approved: true),
                        icon: const Icon(Icons.check),
                        label: const Text('Setujui'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildContentModerationTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 72, color: Colors.amber),
          SizedBox(height: 16),
          Text(
            'Fitur moderasi konten',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Akan tersedia dalam update selanjutnya.\nSaat ini admin dapat menghapus posting\ndari halaman detail.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(alumni) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Alumni'),
        content: Text('Apakah Anda yakin ingin menolak ${alumni.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(adminNotifierProvider.notifier).verifyAlumni(alumni, approved: false);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

}
