import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart' show AppDateUtils;

/// Displays the date title in the app bar
/// Shows "Today", "Yesterday", or the formatted date with optional subtitle
class AppBarTitle extends StatelessWidget {
  final String selectedDate;

  const AppBarTitle({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = AppDateUtils.fromDbFormat(selectedDate);
    final isToday = AppDateUtils.isToday(selectedDate);
    final isYesterday = selectedDate == AppDateUtils.yesterday();
    final now = DateTime.now();
    final isDifferentYear = date.year != now.year;

    String title;
    String? subtitle;

    if (isToday) {
      title = 'Today';
      subtitle = AppDateUtils.toDisplayFormat(date);
    } else if (isYesterday) {
      title = 'Yesterday';
      subtitle = AppDateUtils.toDisplayFormat(date);
    } else if (isDifferentYear) {
      // For dates in different years, show date without year as title
      // and year as subtitle
      title = DateFormat('MMMM d').format(date);
      subtitle = date.year.toString();
    } else {
      // For other dates in current year, just show the date
      title = AppDateUtils.toDisplayFormat(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (subtitle != null)
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}
