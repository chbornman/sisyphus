import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';
import '../core/utils/time_utils.dart';
import '../core/utils/date_utils.dart';
import '../providers/timeslot_provider.dart';
import '../providers/selected_date_provider.dart';
import '../widgets/timeslot/timeslot_list_item.dart';

/// Home screen - Main timeslot list view
/// Displays 48 half-hour timeslots for tracking happiness throughout the day
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Track swipe direction for animation
  int _swipeDirection = 0; // -1 = left, 0 = none, 1 = right

  // Track if we've done the initial scroll to current time
  bool _hasPerformedInitialScroll = false;

  // Store scroll controllers per date to avoid conflicts during animations
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void dispose() {
    // Dispose all scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Get or create scroll controller for a specific date
  ScrollController _getScrollController(String date) {
    if (!_scrollControllers.containsKey(date)) {
      _scrollControllers[date] = ScrollController();
    }
    return _scrollControllers[date]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);

    // Check if viewing today
    final isToday = AppDateUtils.isToday(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(selectedDate, theme),
        actions: [
          // Navigate to previous day
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous day',
            onPressed: _goToPreviousDay,
          ),
          // Jump to today
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Today',
              onPressed: _goToToday,
            ),
          // Navigate to next day (hidden if already at today)
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next day',
              onPressed: _goToNextDay,
            ),
          // Calendar view (placeholder)
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Calendar',
            onPressed: () {
              // TODO: Navigate to calendar screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calendar view coming in Phase 3!')),
              );
            },
          ),
          // Analysis view (placeholder)
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analysis',
            onPressed: () {
              // TODO: Navigate to analysis screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Analysis view coming in Phase 4!')),
              );
            },
          ),
          // Settings (placeholder)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // TODO: Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming in Phase 6!')),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        // Swipe gestures for day navigation
        onHorizontalDragEnd: (details) => _handleSwipe(details, isToday),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            // Slide transition based on swipe direction
            final offsetAnimation = Tween<Offset>(
              begin: Offset(_swipeDirection.toDouble(), 0.0),
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
              data: (timeslots) {
              // Get scroll controller for this specific date
              final scrollController = _getScrollController(selectedDate);

              // Auto-scroll to current time on very first app load (only if viewing today)
              if (isToday && !_hasPerformedInitialScroll) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToCurrentTime(scrollController);
                  _hasPerformedInitialScroll = true;
                });
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Refresh timeslots
                  ref.invalidate(timeslotsProvider);
                },
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing2),
                  itemCount: timeslots.length,
                  itemBuilder: (context, index) {
                    final timeslot = timeslots[index];
                    final currentTimeIndex = isToday ? TimeUtils.getCurrentTimeIndex() : -1;
                    final isCurrentSlot = timeslot.timeIndex == currentTimeIndex;

                    // Check if this timeslot is in the future
                    final isFutureSlot = isToday && timeslot.timeIndex > currentTimeIndex;

                    return TimeslotListItem(
                      key: ValueKey('${timeslot.date}_${timeslot.timeIndex}'),
                      timeslot: timeslot,
                      isCurrentSlot: isCurrentSlot,
                      isFuture: isFutureSlot,
                    );
                  },
                ),
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
                    'Error loading timeslots',
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
                    onPressed: () => ref.invalidate(timeslotsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ), // Close timeslotsAsync.when()
        ), // Close KeyedSubtree
      ), // Close AnimatedSwitcher
    ), // Close GestureDetector
  );
  }

  /// Handle horizontal swipe gestures for day navigation
  void _handleSwipe(DragEndDetails details, bool isToday) {
    // Minimum velocity to count as a swipe (pixels per second)
    const swipeVelocityThreshold = 500.0;

    final velocity = details.primaryVelocity ?? 0;

    // Swipe right (positive velocity) = go to previous day
    if (velocity > swipeVelocityThreshold) {
      setState(() => _swipeDirection = 1); // Coming from right
      ref.read(selectedDateProvider.notifier).previousDay();
    }
    // Swipe left (negative velocity) = go to next day (only if not on today)
    else if (velocity < -swipeVelocityThreshold && !isToday) {
      setState(() => _swipeDirection = -1); // Coming from left
      ref.read(selectedDateProvider.notifier).nextDay();
    }
  }

  /// Navigate to previous day (called by button)
  void _goToPreviousDay() {
    setState(() => _swipeDirection = 1); // Coming from right
    ref.read(selectedDateProvider.notifier).previousDay();
  }

  /// Navigate to next day (called by button)
  void _goToNextDay() {
    setState(() => _swipeDirection = -1); // Coming from left
    ref.read(selectedDateProvider.notifier).nextDay();
  }

  /// Navigate to today (called by button)
  void _goToToday() {
    setState(() => _swipeDirection = 0); // No directional animation
    ref.read(selectedDateProvider.notifier).selectToday();
  }

  /// Build app bar title with date
  Widget _buildAppBarTitle(String selectedDate, ThemeData theme) {
    final date = AppDateUtils.fromDbFormat(selectedDate);
    final isToday = AppDateUtils.isToday(selectedDate);
    final isYesterday = selectedDate == AppDateUtils.yesterday();

    String title;
    if (isToday) {
      title = 'Today';
    } else if (isYesterday) {
      title = 'Yesterday';
    } else {
      title = AppDateUtils.toDisplayFormat(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        if (!isToday)
          Text(
            AppDateUtils.toDisplayFormat(date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  /// Auto-scroll to current time slot
  void _scrollToCurrentTime(ScrollController controller) {
    if (!controller.hasClients) return;

    final currentIndex = TimeUtils.getCurrentTimeIndex();

    // Calculate scroll position
    // Each item is timeslotHeight + vertical margin (2 * spacing1)
    final itemHeight = AppTheme.timeslotHeight + (2 * AppTheme.spacing1);
    final targetPosition = currentIndex * itemHeight;

    // Scroll to position with some offset to center it better
    final maxScroll = controller.position.maxScrollExtent;
    final scrollPosition = (targetPosition - 100).clamp(0.0, maxScroll);

    controller.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
