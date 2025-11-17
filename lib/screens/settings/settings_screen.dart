import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing.dart';
import '../../providers/settings_provider.dart';
import '../../providers/enhanced_notification_provider.dart';
import '../../features/notifications/widgets/notification_diagnostics_dialog.dart';
import '../../features/notifications/models/notification_status.dart';
import 'widgets/section_header.dart';
import 'widgets/theme_toggle.dart';
import 'widgets/accent_color_picker.dart';
import 'widgets/time_format_toggle.dart';
import 'widgets/notification_toggle.dart';
import 'widgets/time_range_picker.dart';

/// Settings screen - Configure app preferences
/// Allows users to customize theme, notifications, and accent color
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Stronger tinted background with accent color
        backgroundColor: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: EdgeInsets.all(AppSpacing.spacing2),
            children: [
              // Notifications Section
              const SectionHeader(title: 'Notifications'),
              SizedBox(height: AppSpacing.spacing2),

              // All notification settings in one card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.spacing2),
                  child: Column(
                    children: [
                      // Notification status (always visible)
                      if (settings.notificationsEnabled)
                        _NotificationStatusIndicator(settings: settings),

                      // Enable reminders toggle
                      NotificationToggle(enabled: settings.notificationsEnabled),

                      // Time range picker (show if enabled)
                      if (settings.notificationsEnabled) ...[
                        const Divider(height: 24),
                        TimeRangePicker(
                          startHour: settings.notificationStartHour,
                          endHour: settings.notificationEndHour,
                          timeFormat: settings.timeFormat,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.spacing4),

              // Appearance Section
              const SectionHeader(title: 'Appearance'),
              SizedBox(height: AppSpacing.spacing2),

              // Time format toggle
              TimeFormatToggle(currentFormat: settings.timeFormat),
              SizedBox(height: AppSpacing.spacing2),

              // Accent color picker
              AccentColorPicker(currentColor: settings.accentColor),
              SizedBox(height: AppSpacing.spacing2),

              // Theme toggle
              ThemeToggle(currentTheme: settings.themeMode),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: AppSpacing.spacing4),
              Text(
                'Error loading settings',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppSpacing.spacing2),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.spacing4),
              FilledButton(
                onPressed: () => ref.invalidate(settingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notification status indicator widget
/// Shows the health status and provides diagnostic/recovery options
class _NotificationStatusIndicator extends ConsumerWidget {
  final dynamic settings;

  const _NotificationStatusIndicator({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusAsync = ref.watch(notificationStatusNotifierProvider);

    return statusAsync.when(
      data: (status) => Column(
        children: [
          // Compact status indicator
          Row(
            children: [
              Icon(
                status.health.icon,
                color: status.health.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status.health.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: status.health.color,
                ),
              ),
              const Spacer(),
              if (status.health == NotificationHealth.unhealthy)
                TextButton(
                  onPressed: () async {
                    final notifier = ref.read(
                      notificationStatusNotifierProvider.notifier,
                    );
                    await notifier.attemptRecovery();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Fix'),
                )
              else
                TextButton(
                  onPressed: () async {
                    final diagnostics = await ref.read(
                      notificationDiagnosticsProvider.future,
                    );

                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => NotificationDiagnosticsDialog(
                          diagnostics: diagnostics,
                          hideScheduledCount: true,
                          onTestNotification: () {
                            ref.read(
                              notificationStatusNotifierProvider.notifier,
                            ).testNotification();
                          },
                          onReschedule: () {
                            ref.read(
                              notificationStatusNotifierProvider.notifier,
                            ).scheduleNotifications(
                              startIndex: settings.notificationStartHour,
                              endIndex: settings.notificationEndHour,
                              enabled: true,
                            );
                          },
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  child: const Text('Details'),
                ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
      loading: () => Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
