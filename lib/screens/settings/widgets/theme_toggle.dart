import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../providers/settings_provider.dart';

/// Theme toggle widget using SegmentedButton
class ThemeToggle extends ConsumerWidget {
  final ThemeMode currentTheme;

  const ThemeToggle({super.key, required this.currentTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppSpacing.spacing2),
                Text('Theme', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: AppSpacing.spacing2),
            Center(
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings_suggest),
                  ),
                ],
                selected: {currentTheme},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateTheme(newSelection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
