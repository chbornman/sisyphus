import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';
import '../core/utils/time_utils.dart';
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
        // Stronger tinted background with accent color
        backgroundColor: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
      ),
      body: settingsAsync.when(
        data: (settings) {
          return ListView(
            padding: EdgeInsets.all(AppTheme.spacing2),
            children: [
              // Notifications Section
              _buildSectionHeader('Notifications', theme),
              SizedBox(height: AppTheme.spacing2),

              // Notification toggle
              _NotificationToggle(enabled: settings.notificationsEnabled),
              SizedBox(height: AppTheme.spacing2),

              // Time range pickers (only show if notifications enabled)
              if (settings.notificationsEnabled)
                _TimeRangePicker(
                  startHour: settings.notificationStartHour,
                  endHour: settings.notificationEndHour,
                  timeFormat: settings.timeFormat,
                ),
              SizedBox(height: AppTheme.spacing4),

              // Appearance Section
              _buildSectionHeader('Appearance', theme),
              SizedBox(height: AppTheme.spacing2),

              // Time format toggle
              _TimeFormatToggle(currentFormat: settings.timeFormat),
              SizedBox(height: AppTheme.spacing2),

              // Accent color picker
              _AccentColorPicker(currentColor: settings.accentColor),
              SizedBox(height: AppTheme.spacing2),

              // Theme toggle
              _ThemeToggle(currentTheme: settings.themeMode),
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
                Text('Theme', style: theme.textTheme.titleMedium),
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
                Text('Accent Color', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),
            Center(
              child: Wrap(
                spacing: AppTheme.spacing2,
                runSpacing: AppTheme.spacing2,
                alignment: WrapAlignment.center,
                children: _colorPalette.map((color) {
                  // Compare colors using toARGB32()
                  final isSelected =
                      color.toARGB32() == currentColor.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .updateAccentColor(color);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                        border: isSelected
                            ? Border.all(
                                // Use subtle border matching home screen timeslot items
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 32)
                          : null,
                    ),
                  );
                }).toList(),
              ),
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
                Text('Time Format', style: theme.textTheme.titleMedium),
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
                  ref
                      .read(settingsProvider.notifier)
                      .updateTimeFormat(newSelection.first);
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
                  Icons.notifications_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppTheme.spacing2),
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
            SizedBox(height: AppTheme.spacing1),
            Padding(
              padding: EdgeInsets.only(left: 20 + AppTheme.spacing2),
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

/// Time range picker widget for notification hours
class _TimeRangePicker extends ConsumerWidget {
  final int startHour;
  final int endHour;
  final TimeFormat timeFormat;

  const _TimeRangePicker({
    required this.startHour,
    required this.endHour,
    required this.timeFormat,
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
                Text('Notification Hours', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),

            // Compact time range display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start time picker (can't be >= end time)
                _HourPicker(
                  hour: startHour,
                  timeFormat: timeFormat,
                  maxIndex: endHour, // Don't show times >= end time
                  onChanged: (newStartHour) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateNotificationHours(newStartHour, endHour);
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
                  child: Text(
                    '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                // End time picker (can't be <= start time)
                _HourPicker(
                  hour: endHour,
                  timeFormat: timeFormat,
                  minIndex: startHour + 1, // Don't show times <= start time
                  onChanged: (newEndHour) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateNotificationHours(startHour, newEndHour);
                  },
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing2),

            // Helper text
            Text(
              'You\'ll receive reminders every 30 minutes during this time range.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Time picker wheel (30-minute increments)
class _HourPicker extends StatefulWidget {
  final int hour; // Actually time index 0-47
  final TimeFormat timeFormat;
  final ValueChanged<int> onChanged;
  final int? minIndex; // Minimum selectable index (inclusive)
  final int? maxIndex; // Maximum selectable index (exclusive)

  const _HourPicker({
    required this.hour,
    required this.timeFormat,
    required this.onChanged,
    this.minIndex,
    this.maxIndex,
  });

  @override
  State<_HourPicker> createState() => _HourPickerState();
}

class _HourPickerState extends State<_HourPicker> {
  String _formatTimeIndex(int timeIndex) {
    return TimeUtils.formatTimeForDisplay(timeIndex, widget.timeFormat);
  }

  void _showWheelPicker(BuildContext context) {
    final theme = Theme.of(context);
    // Buffer the selected index while user scrolls the wheel
    int tempSelectedIndex = widget.hour;

    // Build list of valid time indices based on min/max constraints
    final minIdx = widget.minIndex ?? 0;
    final maxIdx = widget.maxIndex ?? 48;
    final validIndices = List.generate(maxIdx - minIdx, (i) => minIdx + i);

    // Find initial scroll position
    final initialScrollIndex = validIndices.indexOf(widget.hour);

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 300,
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    Text(
                      'Select Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Only call onChanged when Done is tapped
                        widget.onChanged(tempSelectedIndex);
                        Navigator.pop(context);
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              // Wheel picker with selection indicator
              Expanded(
                child: Stack(
                  children: [
                    // Selection highlight background
                    Center(
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // The actual wheel
                    ListWheelScrollView.useDelegate(
                      itemExtent: 50,
                      perspective: 0.005,
                      diameterRatio: 1.2,
                      physics: const FixedExtentScrollPhysics(),
                      controller: FixedExtentScrollController(
                        initialItem: initialScrollIndex.clamp(
                          0,
                          validIndices.length - 1,
                        ),
                      ),
                      onSelectedItemChanged: (wheelIndex) {
                        // Map wheel index to actual time index
                        final timeIndex = validIndices[wheelIndex];
                        // Store selection temporarily and update UI to show new selection
                        setModalState(() {
                          tempSelectedIndex = timeIndex;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, wheelIndex) {
                          if (wheelIndex < 0 ||
                              wheelIndex >= validIndices.length) {
                            return null;
                          }
                          final timeIndex = validIndices[wheelIndex];
                          final isSelected = timeIndex == tempSelectedIndex;
                          return Center(
                            child: Text(
                              _formatTimeIndex(timeIndex),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        childCount: validIndices.length,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showWheelPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing3,
          vertical: AppTheme.spacing2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTimeIndex(widget.hour),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: AppTheme.spacing1),
            Icon(
              Icons.expand_more,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
