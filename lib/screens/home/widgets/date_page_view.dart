import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/spacing.dart';
import '../../../models/timeslot.dart';
import '../../../providers/timeslot_provider.dart';
import '../../../providers/settings_provider.dart';
import 'timeslot_list.dart';

/// Manages the animated date transitions with swipe gestures
/// Wraps the timeslot list in an AnimatedSwitcher for smooth day navigation
class DatePageView extends ConsumerWidget {
  final String selectedDate;
  final bool isToday;
  final int swipeDirection;
  final int currentTimeIndex;
  final ScrollController Function(String date) getScrollController;
  final int? scrollTarget;
  final bool hasPerformedInitialScroll;
  final void Function(ScrollController controller, int timeIndex)
      scrollToTimeslot;
  final void Function(ScrollController controller) scrollToCurrentTime;
  final VoidCallback onInitialScrollPerformed;
  final VoidCallback onScrollTargetUsed;

  const DatePageView({
    super.key,
    required this.selectedDate,
    required this.isToday,
    required this.swipeDirection,
    required this.currentTimeIndex,
    required this.getScrollController,
    required this.scrollTarget,
    required this.hasPerformedInitialScroll,
    required this.scrollToTimeslot,
    required this.scrollToCurrentTime,
    required this.onInitialScrollPerformed,
    required this.onScrollTargetUsed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // Slide transition based on swipe direction
        final offsetAnimation = Tween<Offset>(
          begin: Offset(swipeDirection.toDouble(), 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(selectedDate), // Key ensures animation triggers on date change
        child: timeslotsAsync.when(
          data: (timeslots) =>
              _buildTimeslotList(ref, timeslots, settingsAsync),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(ref, theme, error),
        ),
      ),
    );
  }

  /// Build the timeslot list with proper scrolling behavior
  Widget _buildTimeslotList(
    WidgetRef ref,
    List<Timeslot> timeslots,
    AsyncValue<dynamic> settingsAsync,
  ) {
    // Get scroll controller for this specific date
    final scrollController = getScrollController(selectedDate);

    // Scroll to target timeslot if navigating from analysis screen
    if (scrollTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToTimeslot(scrollController, scrollTarget!);
        // Clear the scroll target after using it
        onScrollTargetUsed();
      });
    }
    // Auto-scroll to current time on very first app load (only if viewing today)
    else if (isToday && !hasPerformedInitialScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToCurrentTime(scrollController);
        onInitialScrollPerformed();
      });
    }

    // Get notification settings
    final notificationsEnabled = settingsAsync.when(
      data: (settings) => settings.notificationsEnabled,
      loading: () => false,
      error: (_, __) => false,
    );
    final notificationStartIndex = settingsAsync.when(
      data: (settings) => settings.notificationStartHour,
      loading: () => AppConstants.defaultNotificationStartHour,
      error: (_, __) => AppConstants.defaultNotificationStartHour,
    );
    final notificationEndIndex = settingsAsync.when(
      data: (settings) => settings.notificationEndHour,
      loading: () => AppConstants.defaultNotificationEndHour,
      error: (_, __) => AppConstants.defaultNotificationEndHour,
    );

    return TimeslotList(
      timeslots: timeslots,
      scrollController: scrollController,
      currentTimeIndex: isToday ? currentTimeIndex : -1,
      isToday: isToday,
      notificationsEnabled: notificationsEnabled,
      notificationStartIndex: notificationStartIndex,
      notificationEndIndex: notificationEndIndex,
      onRefresh: () => ref.invalidate(timeslotsProvider),
    );
  }

  /// Build error state UI
  Widget _buildErrorState(WidgetRef ref, ThemeData theme, Object error) {
    return Center(
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
            'Error loading timeslots',
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
            onPressed: () => ref.invalidate(timeslotsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
