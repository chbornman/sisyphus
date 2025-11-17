import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/app_theme.dart';
import '../core/utils/time_utils.dart';
import '../core/utils/date_utils.dart' show AppDateUtils;
import '../models/timeslot.dart';
import '../providers/timeslot_provider.dart';
import '../providers/selected_date_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/scroll_target_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/database_provider.dart';
import '../providers/deep_link_provider.dart';
import '../features/notifications/services/enhanced_notification_service.dart';
import '../widgets/timeslot/timeslot_list_item.dart';
import '../widgets/timeslot/timeslot_editor_dialog.dart';
import '../widgets/welcome_modal.dart';
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

    // Initialize notifications (reschedule if enabled)
    _initializeNotifications();

    // Show welcome modal if first launch
    _checkAndShowWelcomeModal();

    // Set up notification tap handler
    _setupNotificationHandler();

    // Handle deep links after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDeepLink();
    });
  }

  /// Initialize and reschedule notifications on app startup
  /// This ensures notifications stay scheduled after app updates or device reboots
  Future<void> _initializeNotifications() async {
    try {
      final settingsAsync = ref.read(settingsProvider);
      settingsAsync.whenData((settings) async {
        if (settings.notificationsEnabled) {
          final notificationService = ref.read(notificationServiceProvider);

          // Check if we already have permission before scheduling
          final hasPermission = await notificationService.areNotificationsPermitted();

          if (hasPermission) {
            // Permission already granted - reschedule notifications
            await notificationService.rescheduleNotifications(
              startIndex: settings.notificationStartHour,
              endIndex: settings.notificationEndHour,
            );
          } else {
            // Permission not granted - disable notifications in settings
            // User will need to explicitly enable them (triggering permission request)
            final dbService = ref.read(databaseServiceProvider);
            await dbService.updateSetting('notifications_enabled', 'false');
            ref.invalidate(settingsProvider);
          }
        }
      });
    } catch (e) {
      // Silently fail - notifications are not critical to app functionality
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Check and show welcome modal on first app launch
  void _checkAndShowWelcomeModal() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Wait for settings to load from database
        final settings = await ref.read(settingsProvider.future);

        debugPrint('🎯 Welcome modal check: hasSeenWelcome = ${settings.hasSeenWelcome}');

        if (!settings.hasSeenWelcome && mounted) {
          debugPrint('📱 Showing welcome modal');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const WelcomeModal(),
          );
        } else {
          debugPrint('✅ Welcome already seen, skipping modal');
        }
      } catch (e) {
        debugPrint('❌ Error checking welcome modal: $e');
      }
    });
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
        // Stronger tinted background with accent color
        backgroundColor: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
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

              // Get notification settings
              final notificationsEnabled = settingsAsync.when(
                data: (settings) => settings.notificationsEnabled,
                loading: () => false,
                error: (_, __) => false,
              );
              final notificationStartIndex = settingsAsync.when(
                data: (settings) => settings.notificationStartHour, // Actually time index now
                loading: () => AppConstants.defaultNotificationStartHour, // 7:00 AM
                error: (_, __) => AppConstants.defaultNotificationStartHour,
              );
              final notificationEndIndex = settingsAsync.when(
                data: (settings) => settings.notificationEndHour, // Actually time index now
                loading: () => AppConstants.defaultNotificationEndHour, // 10:00 PM
                error: (_, __) => AppConstants.defaultNotificationEndHour,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  // Refresh timeslots
                  ref.invalidate(timeslotsProvider);
                },
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  itemCount: timeslots.length + 2, // +2 for top and bottom spacers
                  itemBuilder: (context, index) {
                    // Top spacer item
                    if (index == 0) {
                      // Check if first timeslot (00:00, index 0) is outside notification hours
                      // Only show dark background if notifications are enabled
                      final firstSlotIndex = 0;
                      final isFirstSlotOutsideNotificationHours = notificationsEnabled &&
                          (firstSlotIndex < notificationStartIndex || firstSlotIndex >= notificationEndIndex);

                      return Container(
                        height: AppTheme.spacing2,
                        color: isFirstSlotOutsideNotificationHours
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
                              )
                            : null,
                      );
                    }

                    // Bottom spacer item
                    if (index == timeslots.length + 1) {
                      // Check if last timeslot (23:30, index 47) is outside notification hours
                      // Only show dark background if notifications are enabled
                      final lastSlotIndex = 47;
                      final isLastSlotOutsideNotificationHours = notificationsEnabled &&
                          (lastSlotIndex < notificationStartIndex || lastSlotIndex >= notificationEndIndex);

                      return Container(
                        height: AppTheme.spacing4,
                        color: isLastSlotOutsideNotificationHours
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
                              )
                            : null,
                      );
                    }

                    final timeslot = timeslots[index - 1];
                    final currentTimeIndex = isToday ? _currentTimeIndex : -1;
                    final isCurrentSlot = timeslot.timeIndex == currentTimeIndex;

                    // Check if this timeslot is in the future
                    final isFutureSlot = isToday && timeslot.timeIndex > currentTimeIndex;

                    // Check if this timeslot is outside notification hours
                    // Only apply styling if notifications are enabled
                    // Now we can compare time indices directly (both are 0-47)
                    final isOutsideNotificationHours = notificationsEnabled &&
                        (timeslot.timeIndex < notificationStartIndex || timeslot.timeIndex >= notificationEndIndex);

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
    // Account for top spacer (spacing2) plus timeslot height for each item
    final topSpacerHeight = AppTheme.spacing2;
    final itemHeight = AppTheme.timeslotHeight;
    final targetPosition = topSpacerHeight + (timeslotIndex * itemHeight);

    // Scroll to position with some offset to center it better
    final maxScroll = controller.position.maxScrollExtent;
    final scrollPosition = (targetPosition - 100).clamp(0.0, maxScroll);

    controller.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Set up notification tap handler
  void _setupNotificationHandler() {
    // Set the callback for notification taps
    EnhancedNotificationService.onNotificationTap = (timeIndex) {
      // Navigate to today first if not already there
      final currentDate = ref.read(selectedDateProvider);
      final todayDate = DateTime.now();
      final todayString = AppDateUtils.toDbFormat(todayDate);

      if (currentDate != todayString) {
        ref.read(selectedDateProvider.notifier).selectDate(todayDate);
      }

      // Schedule navigation after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToTimeslotAndOpenEditor(timeIndex);
      });
    };
  }

  /// Check for deep link requests
  void _checkForDeepLink() {
    // Listen for deep link requests
    ref.listen<DeepLinkRequest?>(deepLinkNotifierProvider, (previous, next) {
      if (next != null) {
        // Navigate to today if needed
        final currentDate = ref.read(selectedDateProvider);
        final todayDate = DateTime.now();
        final todayString = AppDateUtils.toDbFormat(todayDate);

        if (currentDate != todayString) {
          ref.read(selectedDateProvider.notifier).selectDate(todayDate);
        }

        // Navigate to the timeslot
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateToTimeslotAndOpenEditor(next.timeIndex);

          // Clear the deep link request
          ref.read(deepLinkNotifierProvider.notifier).clear();
        });
      }
    });
  }

  /// Navigate to a specific timeslot and open its editor
  Future<void> _navigateToTimeslotAndOpenEditor(int timeIndex) async {
    // Get the scroll controller for today
    final today = AppDateUtils.toDbFormat(DateTime.now());
    final controller = _getScrollController(today);

    // Wait a bit for the list to be built if needed
    await Future.delayed(const Duration(milliseconds: 100));

    if (controller.hasClients) {
      // Scroll to the timeslot
      _scrollToTimeslot(controller, timeIndex);

      // Wait for scroll to complete
      await Future.delayed(const Duration(milliseconds: 600));

      // Open the editor dialog
      if (mounted) {
        _openTimeslotEditor(timeIndex);
      }
    }
  }

  /// Open the timeslot editor for a specific time index
  void _openTimeslotEditor(int timeIndex) {
    final timeslotsAsync = ref.read(timeslotsProvider);

    timeslotsAsync.whenData((timeslots) {
      // Find the timeslot
      final timeslot = timeslots.firstWhere(
        (t) => t.timeIndex == timeIndex,
        orElse: () {
          // Create a new timeslot if it doesn't exist
          final today = DateTime.now();
          final dateString = AppDateUtils.toDbFormat(today);

          return Timeslot(
            date: dateString,
            timeIndex: timeIndex,
            time: TimeUtils.indexToTime(timeIndex),
            happinessScore: 0,
            createdAt: today,
            updatedAt: today,
          );
        },
      );

      // Show the editor dialog
      showDialog(
        context: context,
        builder: (context) => TimeslotEditorDialog(
          timeslot: timeslot,
          onSave: (description, score) {
            ref.read(timeslotsProvider.notifier).updateTimeslot(
                  timeIndex,
                  score,
                  description,
                );
          },
        ),
      );
    });
  }
}
