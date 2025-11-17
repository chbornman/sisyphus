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
class DatePageView extends ConsumerStatefulWidget {
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
  ConsumerState<DatePageView> createState() => _DatePageViewState();
}

class _DatePageViewState extends ConsumerState<DatePageView> {
  /// Track which scroll target we've already processed to avoid re-scrolling
  int? _processedScrollTarget;

  /// Track if we've performed the initial scroll for this date
  bool _hasScrolledForCurrentDate = false;
  String? _lastScrolledDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    // Reset scroll tracking when date changes
    if (_lastScrolledDate != widget.selectedDate) {
      _hasScrolledForCurrentDate = false;
      _lastScrolledDate = widget.selectedDate;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        // Slide transition based on swipe direction
        final offsetAnimation = Tween<Offset>(
          begin: Offset(widget.swipeDirection.toDouble(), 0.0),
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
        key: ValueKey(widget.selectedDate), // Key ensures animation triggers on date change
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
    final scrollController = widget.getScrollController(widget.selectedDate);

    // Handle scroll target from analysis screen navigation
    // Only scroll if we have a new target that we haven't processed yet
    if (widget.scrollTarget != null &&
        widget.scrollTarget != _processedScrollTarget) {
      _processedScrollTarget = widget.scrollTarget;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scrollController.hasClients) {
          widget.scrollToTimeslot(scrollController, widget.scrollTarget!);
          // Clear the scroll target after using it
          widget.onScrollTargetUsed();
        }
      });
    }
    // Auto-scroll to current time on first load of today's view
    else if (widget.isToday &&
             !widget.hasPerformedInitialScroll &&
             !_hasScrolledForCurrentDate) {
      _hasScrolledForCurrentDate = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scrollController.hasClients) {
          widget.scrollToCurrentTime(scrollController);
          widget.onInitialScrollPerformed();
        }
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
      currentTimeIndex: widget.isToday ? widget.currentTimeIndex : -1,
      isToday: widget.isToday,
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