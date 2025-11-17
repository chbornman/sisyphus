import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';

/// Time format toggle widget
class TimeFormatToggle extends ConsumerWidget {
  final TimeFormat currentFormat;

  const TimeFormatToggle({super.key, required this.currentFormat});

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
                  Icons.access_time_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppSpacing.spacing2),
                Text('Time Format', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: AppSpacing.spacing2),
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
