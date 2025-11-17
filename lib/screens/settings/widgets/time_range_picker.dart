import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/time_utils.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';

/// Time range picker widget for notification hours
class TimeRangePicker extends ConsumerWidget {
  final int startHour;
  final int endHour;
  final TimeFormat timeFormat;

  const TimeRangePicker({
    super.key,
    required this.startHour,
    required this.endHour,
    required this.timeFormat,
  });

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
                  Icons.access_time,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppSpacing.spacing2),
                Text('Notification Hours', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: AppSpacing.spacing2),

            // Compact time range display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Start time picker (can't be >= end time)
                HourPicker(
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
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
                  child: Text(
                    '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                // End time picker (can't be <= start time)
                HourPicker(
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
            SizedBox(height: AppSpacing.spacing2),

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
class HourPicker extends StatefulWidget {
  final int hour; // Actually time index 0-47
  final TimeFormat timeFormat;
  final ValueChanged<int> onChanged;
  final int? minIndex; // Minimum selectable index (inclusive)
  final int? maxIndex; // Maximum selectable index (exclusive)

  const HourPicker({
    super.key,
    required this.hour,
    required this.timeFormat,
    required this.onChanged,
    this.minIndex,
    this.maxIndex,
  });

  @override
  State<HourPicker> createState() => _HourPickerState();
}

class _HourPickerState extends State<HourPicker> {
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
                padding: EdgeInsets.all(AppSpacing.spacing2),
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
                          horizontal: AppSpacing.spacing3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.borderRadius,
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
          horizontal: AppSpacing.spacing3,
          vertical: AppSpacing.spacing2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
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
            SizedBox(width: AppSpacing.spacing1),
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
