import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/notification_service.dart';
import '../providers/notifications_provider.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);
    final notifSvc = ref.read(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (list.any((e) => !e.read))
            TextButton(
              onPressed: notifier.markAllRead,
              child: const Text('Tandai terbaca'),
            ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum ada notifikasi'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = await notifSvc.ensurePermission(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Izin diberikan' : 'Izin ditolak')), 
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Aktifkan Notifikasi'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = list[index];
                return ListTile(
                  leading: Icon(n.read ? Icons.notifications_none : Icons.notifications_active_outlined),
                  title: Text(n.title),
                  subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    timeOfDayLabel(n.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    notifier.markRead(n.id);
                    if (n.route != null && n.route!.isNotEmpty) {
                      context.go(n.route!);
                    }
                  },
                );
              },
            ),
    );
  }
}

String timeOfDayLabel(DateTime dt) {
  final now = DateTime.now();
  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '${dt.day}/${dt.month}/${dt.year % 100}';
}
