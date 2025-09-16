import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../settings/providers/settings_controller.dart';

class ThemeToggle extends ConsumerWidget {
  final bool showLabel;
  
  const ThemeToggle({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final isDark = settings.themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          if (showLabel) ...[
            const SizedBox(width: 12),
            Text(
              isDark ? 'Mode Gelap' : 'Mode Terang',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
          ] else
            const SizedBox(width: 8),
          Switch.adaptive(
            value: isDark,
            onChanged: (value) {
              final newMode = value ? ThemeMode.dark : ThemeMode.light;
              ref.read(settingsControllerProvider.notifier).updateThemeMode(newMode);
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
