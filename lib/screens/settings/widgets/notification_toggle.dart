import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../providers/settings_provider.dart';

/// Notification toggle widget
class NotificationToggle extends ConsumerWidget {
  final bool enabled;

  const NotificationToggle({super.key, required this.enabled});

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
                  Icons.notifications_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppSpacing.spacing2),
                Text('Enable Reminders', style: theme.textTheme.titleMedium),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleNotifications(value);
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.spacing1),
            Padding(
              padding: EdgeInsets.only(left: 20 + AppSpacing.spacing2),
              child: Text(
                'Get notified every 30 minutes to track your happiness',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
