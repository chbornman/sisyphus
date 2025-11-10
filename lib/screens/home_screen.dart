import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_theme.dart';
import '../core/utils/time_utils.dart';
import '../core/utils/date_utils.dart';
import '../providers/timeslot_provider.dart';
import '../providers/selected_date_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/scroll_target_provider.dart';
import '../widgets/timeslot/timeslot_list_item.dart';
import 'analysis_screen.dart';
import 'settings_screen.dart';

/// Home screen - Main timeslot list view
/// Displays 48 half-hour timeslots for tracking happiness throughout the day
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  // Track swipe direction for animation
  int _swipeDirection = 0; // -1 = left, 0 = none, 1 = right

  // Track if we've done the initial scroll to current time
  bool _hasPerformedInitialScroll = false;

  // Store scroll controllers per date to avoid conflicts during animations
  final Map<String, ScrollController> _scrollControllers = {};

  // Timer to check for timeslot changes
  Timer? _timeslotUpdateTimer;

  // Track current timeslot index to detect changes
  int _currentTimeIndex = -1;

  @override
  void initState() {
    super.initState();
    _currentTimeIndex = TimeUtils.getCurrentTimeIndex();

    // Listen for app lifecycle changes (background/foreground)
    WidgetsBinding.instance.addObserver(this);

    // Schedule timer for next timeslot transition
    _scheduleNextTimeslotUpdate();
  }

  @override
  void dispose() {
    // Stop listening to lifecycle changes
    WidgetsBinding.instance.removeObserver(this);

    // Cancel timer
    _timeslotUpdateTimer?.cancel();

    // Dispose all scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app returns to foreground, check if timeslot has changed
    if (state == AppLifecycleState.resumed) {
      final newTimeIndex = TimeUtils.getCurrentTimeIndex();
      if (newTimeIndex != _currentTimeIndex) {
        setState(() {
          _currentTimeIndex = newTimeIndex;
        });
      }

      // Reschedule timer in case it was suspended
      _scheduleNextTimeslotUpdate();
    }
  }

  /// Schedule a timer to fire at the next timeslot boundary (00 or 30 minutes)
  /// This ensures UI updates exactly when transitioning to a new timeslot
  void _scheduleNextTimeslotUpdate() {
    final now = DateTime.now();

    // Calculate minutes until next timeslot boundary
    // Timeslots start at :00 and :30
    final currentMinute = now.minute;
    final minutesUntilNext = currentMinute < 30
        ? 30 - currentMinute
        : 60 - currentMinute;

    // Add a small buffer to ensure we're past the boundary
    final duration = Duration(minutes: minutesUntilNext, seconds: 1);

    // Schedule single-shot timer
    _timeslotUpdateTimer?.cancel();
    _timeslotUpdateTimer = Timer(duration, _onTimeslotChange);
  }

  /// Called when timeslot changes - update UI and schedule next timer
  void _onTimeslotChange() {
    final newTimeIndex = TimeUtils.getCurrentTimeIndex();

    setState(() {
      _currentTimeIndex = newTimeIndex;
    });

    // Schedule next update
    _scheduleNextTimeslotUpdate();
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
    final settingsAsync = ref.watch(settingsProvider);
    final scrollTarget = ref.watch(scrollTargetProvider);

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
            visualDensity: VisualDensity.compact,
            onPressed: _goToPreviousDay,
          ),
          // Jump to today
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'Today',
              visualDensity: VisualDensity.compact,
              onPressed: _goToToday,
            ),
          // Navigate to next day (hidden if already at today)
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next day',
              visualDensity: VisualDensity.compact,
              onPressed: _goToNextDay,
            ),
          // Analysis view
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analysis',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AnalysisScreen(),
                ),
              );
            },
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
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

              // Scroll to target timeslot if navigating from analysis screen
              if (scrollTarget != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToTimeslot(scrollController, scrollTarget);
                  // Clear the scroll target after using it
                  ref.read(scrollTargetProvider.notifier).clearTarget();
                });
              }
              // Auto-scroll to current time on very first app load (only if viewing today)
              else if (isToday && !_hasPerformedInitialScroll) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToCurrentTime(scrollController);
                  _hasPerformedInitialScroll = true;
                });
              }

              // Get notification hours from settings
              final notificationStartHour = settingsAsync.when(
                data: (settings) => settings.notificationStartHour,
                loading: () => 7,
                error: (_, __) => 7,
              );
              final notificationEndHour = settingsAsync.when(
                data: (settings) => settings.notificationEndHour,
                loading: () => 22,
                error: (_, __) => 22,
              );

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
                    final currentTimeIndex = isToday ? _currentTimeIndex : -1;
                    final isCurrentSlot = timeslot.timeIndex == currentTimeIndex;

                    // Check if this timeslot is in the future
                    final isFutureSlot = isToday && timeslot.timeIndex > currentTimeIndex;

                    // Check if this timeslot is outside notification hours
                    // Convert time index to hour (0-47 -> 0-23)
                    final slotHour = timeslot.timeIndex ~/ 2;
                    final isOutsideNotificationHours = slotHour < notificationStartHour || slotHour >= notificationEndHour;

                    return TimeslotListItem(
                      key: ValueKey('${timeslot.date}_${timeslot.timeIndex}'),
                      timeslot: timeslot,
                      isCurrentSlot: isCurrentSlot,
                      isFuture: isFutureSlot,
                      isOutsideNotificationHours: isOutsideNotificationHours,
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

  /// Auto-scroll to current time slot
  void _scrollToCurrentTime(ScrollController controller) {
    if (!controller.hasClients) return;

    final currentIndex = TimeUtils.getCurrentTimeIndex();
    _scrollToTimeslot(controller, currentIndex);
  }

  /// Scroll to a specific timeslot index
  void _scrollToTimeslot(ScrollController controller, int timeslotIndex) {
    if (!controller.hasClients) return;

    // Calculate scroll position
    // Each item is timeslotHeight + vertical margin (2 * spacing1)
    final itemHeight = AppTheme.timeslotHeight + (2 * AppTheme.spacing1);
    final targetPosition = timeslotIndex * itemHeight;

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
