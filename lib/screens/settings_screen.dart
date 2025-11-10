import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';

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
        // Always show tinted background
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: EdgeInsets.all(AppTheme.spacing2),
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance', theme),
              SizedBox(height: AppTheme.spacing2),

              // Theme toggle
              _ThemeToggle(currentTheme: settings.themeMode),
              SizedBox(height: AppTheme.spacing2),

              // Accent color picker
              _AccentColorPicker(currentColor: settings.accentColor),
              SizedBox(height: AppTheme.spacing2),

              // Time format toggle
              _TimeFormatToggle(currentFormat: settings.timeFormat),
              SizedBox(height: AppTheme.spacing4),

              // Notifications Section
              _buildSectionHeader('Notifications', theme),
              SizedBox(height: AppTheme.spacing2),

              // Notification toggle
              _NotificationToggle(
                enabled: settings.notificationsEnabled,
              ),
              SizedBox(height: AppTheme.spacing2),

              // Time range pickers (only show if notifications enabled)
              if (settings.notificationsEnabled) ...[
                _TimeRangePicker(
                  startHour: settings.notificationStartHour,
                  endHour: settings.notificationEndHour,
                ),
                SizedBox(height: AppTheme.spacing2),
                Text(
                  'You\'ll receive reminders every 30 minutes during this time range.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],

              SizedBox(height: AppTheme.spacing4),

              // About Section
              _buildSectionHeader('About', theme),
              SizedBox(height: AppTheme.spacing2),

              ListTile(
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.info_outline),
              ),

              ListTile(
                title: const Text('Privacy'),
                subtitle: const Text('All data is stored locally on your device'),
                leading: const Icon(Icons.privacy_tip_outlined),
              ),
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
              SizedBox(height: AppTheme.spacing4),
              Text(
                'Error loading settings',
                style: theme.textTheme.headlineSmall,
              ),
              SizedBox(height: AppTheme.spacing2),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing4),
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

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(left: AppTheme.spacing2),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Theme toggle widget using SegmentedButton
class _ThemeToggle extends ConsumerWidget {
  final ThemeMode currentTheme;

  const _ThemeToggle({required this.currentTheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing2),
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
                SizedBox(width: AppTheme.spacing2),
                Text(
                  'Theme',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),
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
                  ref.read(settingsProvider.notifier).updateTheme(newSelection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accent color picker widget
class _AccentColorPicker extends ConsumerWidget {
  final Color currentColor;

  const _AccentColorPicker({required this.currentColor});

  // Predefined color palette
  static final List<Color> _colorPalette = [
    const Color(0xFF6366F1), // Indigo (default)
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Green
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppTheme.spacing2),
                Text(
                  'Accent Color',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),
            Wrap(
              spacing: AppTheme.spacing2,
              runSpacing: AppTheme.spacing2,
              children: _colorPalette.map((color) {
                // Compare colors using toARGB32()
                final isSelected = color.toARGB32() == currentColor.toARGB32();
                return GestureDetector(
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateAccentColor(color);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time format toggle widget
class _TimeFormatToggle extends ConsumerWidget {
  final TimeFormat currentFormat;

  const _TimeFormatToggle({required this.currentFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppTheme.spacing2),
                Text(
                  'Time Format',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),
            Center(
              child: SegmentedButton<TimeFormat>(
                segments: const [
                  ButtonSegment(
                    value: TimeFormat.twelveHour,
                    label: Text('12-hour'),
                  ),
                  ButtonSegment(
                    value: TimeFormat.twentyFourHour,
                    label: Text('24-hour'),
                  ),
                ],
                selected: {currentFormat},
                onSelectionChanged: (Set<TimeFormat> newSelection) {
                  ref.read(settingsProvider.notifier).updateTimeFormat(newSelection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification toggle widget
class _NotificationToggle extends ConsumerWidget {
  final bool enabled;

  const _NotificationToggle({required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: SwitchListTile(
        value: enabled,
        onChanged: (value) {
          ref.read(settingsProvider.notifier).toggleNotifications(value);
        },
        title: const Text('Enable Reminders'),
        subtitle: const Text('Get notified every 30 minutes to track your happiness'),
        secondary: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

/// Time range picker widget for notification hours
class _TimeRangePicker extends ConsumerWidget {
  final int startHour;
  final int endHour;

  const _TimeRangePicker({
    required this.startHour,
    required this.endHour,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppTheme.spacing2),
                Text(
                  'Notification Hours',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing3),

            // Start time picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Start time',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                _HourPicker(
                  hour: startHour,
                  onChanged: (newStartHour) {
                    if (newStartHour < endHour) {
                      ref.read(settingsProvider.notifier).updateNotificationHours(
                        newStartHour,
                        endHour,
                      );
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),

            // End time picker
            Row(
              children: [
                Expanded(
                  child: Text(
                    'End time',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                _HourPicker(
                  hour: endHour,
                  onChanged: (newEndHour) {
                    if (newEndHour > startHour) {
                      ref.read(settingsProvider.notifier).updateNotificationHours(
                        startHour,
                        newEndHour,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Hour picker dropdown
class _HourPicker extends StatelessWidget {
  final int hour;
  final ValueChanged<int> onChanged;

  const _HourPicker({
    required this.hour,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: hour,
          items: List.generate(24, (index) {
            final period = index < 12 ? 'AM' : 'PM';
            final displayHour = index == 0 ? 12 : (index > 12 ? index - 12 : index);
            return DropdownMenuItem(
              value: index,
              child: Text('$displayHour:00 $period'),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
