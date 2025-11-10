import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_theme.dart';
import '../core/utils/color_utils.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/time_utils.dart';
import '../models/app_settings.dart';
import '../models/timeslot.dart';
import '../providers/settings_provider.dart';
import '../providers/database_provider.dart';
import '../providers/selected_date_provider.dart';
import '../providers/scroll_target_provider.dart';

/// Time filter options for memorable moments
enum TimeFilter {
  pastWeek(7, 'Past Week'),
  pastMonth(30, 'Past Month'),
  pastYear(365, 'Past Year');

  final int days;
  final String label;
  const TimeFilter(this.days, this.label);
}

/// Analysis screen - Heatmap and insights view
/// Visualizes happiness patterns and highlights top/bottom moments
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  // Moments toggle (true = top moments, false = bottom moments)
  bool _showTopMoments = true;

  // Time filter for memorable moments
  TimeFilter _selectedTimeFilter = TimeFilter.pastMonth;

  // Carousel auto-advance
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;

  // Heatmap scroll controller
  late ScrollController _heatmapScrollController;
  bool _hasScrolledToToday = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heatmapScrollController = ScrollController();
    _startCarouselAutoAdvance();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    _heatmapScrollController.dispose();
    super.dispose();
  }

  /// Start carousel auto-advance timer (every 5 seconds)
  void _startCarouselAutoAdvance() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (_pageController.hasClients) {
          // Calculate next page
          final nextPage = (_currentCarouselPage + 1) % 5; // Max 5 moments

          // If looping back to start, jump instead of animating to prevent long scroll
          if (nextPage == 0 && _currentCarouselPage == 4) {
            _pageController.jumpToPage(nextPage);
            setState(() {
              _currentCarouselPage = nextPage;
            });
          } else {
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            setState(() {
              _currentCarouselPage = nextPage;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        // Stronger tinted background with accent color
        backgroundColor: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.08),
          theme.colorScheme.surface,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacing4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heatmap section
            _buildSectionHeader('Happiness Patterns', theme),
            SizedBox(height: AppTheme.spacing3),
            _buildHeatmap(theme),
            SizedBox(height: AppTheme.spacing2),

            // Moments carousel section
            _buildSectionHeader('Memorable Moments', theme),
            SizedBox(height: AppTheme.spacing3),
            _buildMomentsCarousel(theme),
            SizedBox(height: AppTheme.spacing2),
            _buildCarouselDots(theme),
            SizedBox(height: AppTheme.spacing3),
            _buildMomentsControls(theme),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build heatmap visualization
  Widget _buildHeatmap(ThemeData theme) {
    return _HeatmapWidget(
      scrollController: _heatmapScrollController,
      hasScrolledToToday: _hasScrolledToToday,
      onScrollComplete: () {
        _hasScrolledToToday = true;
      },
    );
  }

  /// Build moments controls (top/bottom toggle + time filter)
  Widget _buildMomentsControls(ThemeData theme) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Top/Bottom toggle - takes most of the width
          Expanded(
            flex: 3,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Top 5'),
                  icon: Icon(Icons.sentiment_very_satisfied),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Bot 5'),
                  icon: Icon(Icons.sentiment_very_dissatisfied),
                ),
              ],
              selected: {_showTopMoments},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _showTopMoments = newSelection.first;
                });
              },
            ),
          ),
          SizedBox(width: AppTheme.spacing1),
          // Time filter - compact, takes less width
          Expanded(
            flex: 2,
            child: SegmentedButton<TimeFilter>(
              showSelectedIcon: false,
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 4),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: const [
                ButtonSegment(
                  value: TimeFilter.pastWeek,
                  label: Text('W', style: TextStyle(fontSize: 13)),
                ),
                ButtonSegment(
                  value: TimeFilter.pastMonth,
                  label: Text('M', style: TextStyle(fontSize: 13)),
                ),
                ButtonSegment(
                  value: TimeFilter.pastYear,
                  label: Text('Y', style: TextStyle(fontSize: 13)),
                ),
              ],
              selected: {_selectedTimeFilter},
              onSelectionChanged: (Set<TimeFilter> newSelection) {
                setState(() {
                  _selectedTimeFilter = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build moments carousel
  Widget _buildMomentsCarousel(ThemeData theme) {
    final dbService = ref.watch(databaseServiceProvider);
    final settingsAsync = ref.watch(settingsProvider);

    // Get accent color
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    // Get time format
    final timeFormat = settingsAsync.when(
      data: (settings) => settings.timeFormat,
      loading: () => TimeFormat.twelveHour,
      error: (_, __) => TimeFormat.twelveHour,
    );

    // Calculate date range based on selected time filter
    final endDate = AppDateUtils.toDbFormat(DateTime.now());
    final startDate = AppDateUtils.toDbFormat(
      DateTime.now().subtract(Duration(days: _selectedTimeFilter.days)),
    );

    return FutureBuilder<List<Timeslot>>(
      future: dbService.getTimeslotsInRange(startDate, endDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Filter and sort moments
        final allMoments = snapshot.data!
            .where((t) => t.happinessScore > 0) // Only tracked slots
            .toList();

        if (allMoments.isEmpty) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Center(
              child: Text(
                'No tracked moments in this timeframe',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        // Show message if fewer than 5 timeslots tracked
        if (allMoments.length < 5) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(AppTheme.spacing4),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/app_icon.png',
                    width: 56,
                    height: 56,
                    opacity: const AlwaysStoppedAnimation(0.5),
                  ),
                  SizedBox(height: AppTheme.spacing2),
                  Text(
                    'Check back once you\'ve logged 5 timeslots',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.spacing1),
                  Text(
                    'Track your happiness throughout the day to see your top and bottom moments',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Sort and take top/bottom 5
        final moments = _showTopMoments
            ? (allMoments..sort((a, b) => b.happinessScore.compareTo(a.happinessScore)))
                .take(5)
                .toList()
            : (allMoments..sort((a, b) => a.happinessScore.compareTo(b.happinessScore)))
                .take(5)
                .toList();

        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: moments.length,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            itemBuilder: (context, index) {
              final moment = moments[index];
              return _buildMomentCard(moment, theme, accentColor, timeFormat);
            },
          ),
        );
      },
    );
  }

  /// Build individual moment card
  Widget _buildMomentCard(
    Timeslot moment,
    ThemeData theme,
    Color accentColor,
    TimeFormat timeFormat,
  ) {
    final scoreColor = ColorUtils.getTimeslotColor(accentColor, moment.happinessScore);
    final formattedTime = TimeUtils.formatTimeForDisplay(moment.timeIndex, timeFormat);
    final formattedDate = AppDateUtils.toDisplayFormat(
      AppDateUtils.fromDbFormat(moment.date),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
      padding: EdgeInsets.all(AppTheme.spacing3),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: scoreColor.a * 0.2),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: scoreColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score badge - fixed size for consistency
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                moment.happinessScore.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacing2),

          // Description - prominent display
          if (moment.description != null && moment.description!.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing2),
              child: Text(
                moment.description!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              'No description',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),

          SizedBox(height: AppTheme.spacing2),

          // Date and time on same line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                ' • ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                formattedTime,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build navigation dots for carousel
  /// Always shows 5 dots to indicate the maximum number of moments
  Widget _buildCarouselDots(ThemeData theme) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final isActive = index == _currentCarouselPage;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing1 / 2),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          );
        }),
      ),
    );
  }
}

/// Separate widget for heatmap to prevent unnecessary rebuilds
/// when carousel state changes in parent widget
class _HeatmapWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final bool hasScrolledToToday;
  final VoidCallback onScrollComplete;

  const _HeatmapWidget({
    required this.scrollController,
    required this.hasScrolledToToday,
    required this.onScrollComplete,
  });

  @override
  ConsumerState<_HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends ConsumerState<_HeatmapWidget> {
  // Tap vs drag detection
  // WHY: Track initial tap position to distinguish between taps and scroll drags.
  // Only trigger navigation if finger hasn't moved more than threshold (10px).
  double? _tapDownX;
  double? _tapDownY;

  @override
  Widget build(BuildContext context) {
    // Use ref.watch() to properly react to provider changes
    // WHY: ref.read() in build is safe and proper. ref.watch() ensures we get
    // fresh data and rebuilds when the provider changes.
    final dbService = ref.watch(databaseServiceProvider);

    // Calculate date range fresh on each build
    // WHY: This is cheap (just date arithmetic) and ensures we always show
    // the current date range. The endDate is calculated as the END of today,
    // not midnight, to ensure today is fully included.
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final startDate = endDate.subtract(const Duration(days: 90));
    final dateRangeStart = AppDateUtils.toDbFormat(startDate);
    final dateRangeEnd = AppDateUtils.toDbFormat(endDate);

    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    // Get accent color
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    return FutureBuilder<List<Timeslot>>(
      // Fetch data using the freshly calculated date range
      // WHY: We calculate dates fresh each build to ensure we always show current data.
      // FutureBuilder will still cache the future as long as the parameters don't change.
      future: dbService.getTimeslotsInRange(dateRangeStart, dateRangeEnd),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Group timeslots by date
        final Map<String, List<Timeslot>> slotsByDate = {};
        for (final slot in snapshot.data!) {
          slotsByDate.putIfAbsent(slot.date, () => []).add(slot);
        }

        // Get list of dates in range
        final dates = <String>[];
        var currentDate = startDate;
        while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
          dates.add(AppDateUtils.toDbFormat(currentDate));
          currentDate = currentDate.add(const Duration(days: 1));
        }

        if (dates.isEmpty) {
          return Container(
            height: 300,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Center(
              child: Text(
                'No data in this timeframe',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        // Scroll to show today on the right side of the 14-day viewport
        if (!widget.hasScrolledToToday) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.scrollController.hasClients) {
              // Calculate position to show last 14 days ending with today
              final totalDays = dates.length;
              const columnWidth = 20.0 + 8.0; // width + spacing
              const visibleDays = 14;

              // If we have more than 14 days, scroll to show the last 14
              if (totalDays > visibleDays) {
                final scrollPosition = (totalDays - visibleDays) * columnWidth;
                widget.scrollController.jumpTo(scrollPosition);
              } else {
                // If we have 14 or fewer days, don't scroll
                widget.scrollController.jumpTo(0);
              }

              widget.onScrollComplete();
            }
          });
        }

        const columnWidth = 20.0 + 8.0; // width + spacing
        const visibleDays = 14;
        final viewportWidth = columnWidth * visibleDays;

        return SizedBox(
          height: 315, // Increased to accommodate month labels
          width: viewportWidth,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heatmap grid
                ...dates.map((date) {
                  final daySlots = slotsByDate[date] ?? [];
                  return _buildDayColumn(date, daySlots, accentColor, theme);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a single day column of dots
  Widget _buildDayColumn(
    String date,
    List<Timeslot> daySlots,
    Color accentColor,
    ThemeData theme,
  ) {
    // Create map of timeIndex -> happiness score for quick lookup
    final Map<int, int> scoreByIndex = {
      for (var slot in daySlots) slot.timeIndex: slot.happinessScore,
    };

    final dateObj = AppDateUtils.fromDbFormat(date);

    return GestureDetector(
      // Make entire column area tappable, not just the dots
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        // Store initial tap position for drag threshold detection
        // WHY: We need to distinguish between taps (navigation) and drags (scrolling).
        // Store the position here, then check movement in onTapUp.
        _tapDownX = details.localPosition.dx;
        _tapDownY = details.localPosition.dy;
      },
      onTapUp: (details) {
        // Only trigger navigation if finger hasn't moved more than 10px
        // WHY: Prevents accidental navigation when user is trying to scroll.
        // 10px is the standard touch slop threshold on mobile platforms.
        const dragThreshold = 10.0;
        final dx = (details.localPosition.dx - _tapDownX!).abs();
        final dy = (details.localPosition.dy - _tapDownY!).abs();

        if (dx < dragThreshold && dy < dragThreshold) {
          // It's a tap, not a drag - navigate to the timeslot
          // Calculate which timeslot was tapped based on y-position
          // Skip the month label (12px) and date header (~20px) = ~32px offset
          const headerOffset = 32.0;
          final tapY = details.localPosition.dy - headerOffset;

          // Each dot is 5px tall with 0.5px margin = 5.5px per timeslot
          const dotHeight = 5.5;
          final timeslotIndex = (tapY / dotHeight).floor().clamp(0, 47);

          // Update selected date and scroll target
          ref.read(selectedDateProvider.notifier).selectDate(dateObj);
          ref.read(scrollTargetProvider.notifier).setTarget(timeslotIndex);

          // Navigate back to home screen
          Navigator.of(context).pop();
        }
        // If movement exceeded threshold, do nothing (user was scrolling)
      },
      child: Padding(
        padding: EdgeInsets.only(right: AppTheme.spacing1),
        child: SizedBox(
          width: 20, // Fixed width for consistent spacing
          child: Column(
            children: [
            // Month label (show on every column)
            SizedBox(
              height: 12,
              child: Text(
                _getMonthAbbreviation(dateObj.month),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Date header (abbreviated, centered)
            Text(
              dateObj.day.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing1),

            // 48 tiny dots (one per timeslot)
            ...List.generate(48, (timeIndex) {
              final score = scoreByIndex[timeIndex] ?? 0;
              final hasData = score > 0;

              final dotColor = hasData
                  ? ColorUtils.getTimeslotColor(accentColor, score)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05);

              return Container(
                width: 6, // Tiny dot width
                height: 5, // Tiny dot height (matches row height)
                margin: EdgeInsets.only(bottom: 0.5),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}

  /// Get month abbreviation from month number (1-12)
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
