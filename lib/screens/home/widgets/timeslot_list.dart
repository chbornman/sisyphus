import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../../../models/timeslot.dart';
import '../../../widgets/timeslot/timeslot_list_item.dart';

/// Builds the scrollable list of timeslots for a single day
/// Handles rendering of timeslot items with appropriate styling for
/// current time, future slots, and notification hours
class TimeslotList extends StatelessWidget {
  final List<Timeslot> timeslots;
  final ScrollController scrollController;
  final int currentTimeIndex;
  final bool isToday;
  final bool notificationsEnabled;
  final int notificationStartIndex;
  final int notificationEndIndex;
  final VoidCallback onRefresh;

  const TimeslotList({
    super.key,
    required this.timeslots,
    required this.scrollController,
    required this.currentTimeIndex,
    required this.isToday,
    required this.notificationsEnabled,
    required this.notificationStartIndex,
    required this.notificationEndIndex,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: timeslots.length + 2, // +2 for top and bottom spacers
        itemBuilder: (context, index) {
          // Top spacer item
          if (index == 0) {
            return _buildTopSpacer(theme);
          }

          // Bottom spacer item
          if (index == timeslots.length + 1) {
            return _buildBottomSpacer(theme);
          }

          return _buildTimeslotItem(timeslots[index - 1]);
        },
      ),
    );
  }

  /// Build the top spacer with appropriate background color
  Widget _buildTopSpacer(ThemeData theme) {
    // Check if first timeslot (00:00, index 0) is outside notification hours
    // Only show dark background if notifications are enabled
    const firstSlotIndex = 0;
    final isFirstSlotOutsideNotificationHours = notificationsEnabled &&
        (firstSlotIndex < notificationStartIndex ||
            firstSlotIndex >= notificationEndIndex);

    return Container(
      height: AppSpacing.spacing2,
      color: isFirstSlotOutsideNotificationHours
          ? theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
            )
          : null,
    );
  }

  /// Build the bottom spacer with appropriate background color
  Widget _buildBottomSpacer(ThemeData theme) {
    // Check if last timeslot (23:30, index 47) is outside notification hours
    // Only show dark background if notifications are enabled
    const lastSlotIndex = 47;
    final isLastSlotOutsideNotificationHours = notificationsEnabled &&
        (lastSlotIndex < notificationStartIndex ||
            lastSlotIndex >= notificationEndIndex);

    return Container(
      height: AppSpacing.spacing4,
      color: isLastSlotOutsideNotificationHours
          ? theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
            )
          : null,
    );
  }

  /// Build a single timeslot list item
  Widget _buildTimeslotItem(Timeslot timeslot) {
    final isCurrentSlot = timeslot.timeIndex == currentTimeIndex;

    // Check if this timeslot is in the future
    final isFutureSlot = isToday && timeslot.timeIndex > currentTimeIndex;

    // Check if this timeslot is outside notification hours
    // Only apply styling if notifications are enabled
    // Now we can compare time indices directly (both are 0-47)
    final isOutsideNotificationHours = notificationsEnabled &&
        (timeslot.timeIndex < notificationStartIndex ||
            timeslot.timeIndex >= notificationEndIndex);

    return TimeslotListItem(
      key: ValueKey('${timeslot.date}_${timeslot.timeIndex}'),
      timeslot: timeslot,
      isCurrentSlot: isCurrentSlot,
      isFuture: isFutureSlot,
      isOutsideNotificationHours: isOutsideNotificationHours,
    );
  }
}
