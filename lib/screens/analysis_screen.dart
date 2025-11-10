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

  // Current visible month in heatmap
  String _currentVisibleMonth = '';

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
          // Get total pages from current moments list
          // This will be calculated when we have the actual data
          _currentCarouselPage = (_currentCarouselPage + 1) % 5; // Max 5 moments
          _pageController.animateToPage(
            _currentCarouselPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
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
            SizedBox(height: AppTheme.spacing6),

            // Moments carousel section
            _buildSectionHeader('Memorable Moments', theme),
            SizedBox(height: AppTheme.spacing3),
            _buildMomentsControls(theme),
            SizedBox(height: AppTheme.spacing3),
            _buildMomentsCarousel(theme),
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
      onVisibleMonthChanged: (month) {
        if (_currentVisibleMonth != month) {
          setState(() {
            _currentVisibleMonth = month;
          });
        }
      },
      currentVisibleMonth: _currentVisibleMonth,
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
        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 2),
        border: Border.all(
          color: scoreColor,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Score badge
          Container(
            padding: EdgeInsets.all(AppTheme.spacing2),
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              moment.happinessScore.toString(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacing2),

          // Date and time
          Text(
            formattedDate,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            formattedTime,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          // Description
          SizedBox(height: AppTheme.spacing1),
          if (moment.description != null && moment.description!.isNotEmpty)
            Text(
              moment.description!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        ],
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
  final ValueChanged<String> onVisibleMonthChanged;
  final String currentVisibleMonth;

  const _HeatmapWidget({
    required this.scrollController,
    required this.hasScrolledToToday,
    required this.onScrollComplete,
    required this.onVisibleMonthChanged,
    required this.currentVisibleMonth,
  });

  @override
  ConsumerState<_HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends ConsumerState<_HeatmapWidget> {
  List<String> _allDates = [];
  Future<List<Timeslot>>? _timeslotsFuture;
  String? _cachedDateRange;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _initializeData() {
    final dbService = ref.read(databaseServiceProvider);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90));
    final dateRangeStart = AppDateUtils.toDbFormat(startDate);
    final dateRangeEnd = AppDateUtils.toDbFormat(endDate);
    final dateRangeKey = '$dateRangeStart-$dateRangeEnd';

    // Only create new Future if date range changed (e.g., day changed)
    if (_cachedDateRange != dateRangeKey) {
      _cachedDateRange = dateRangeKey;
      _timeslotsFuture = dbService.getTimeslotsInRange(dateRangeStart, dateRangeEnd);
    }
  }

  void _onScroll() {
    if (_allDates.isEmpty || !widget.scrollController.hasClients) return;

    // Calculate which date is at the left edge based on scroll position
    const columnWidth = 20.0 + 8.0; // width (20) + right padding (8)
    final scrollOffset = widget.scrollController.offset;
    final columnIndex = (scrollOffset / columnWidth).floor();

    if (columnIndex >= 0 && columnIndex < _allDates.length) {
      final leftDate = AppDateUtils.fromDbFormat(_allDates[columnIndex]);

      // Check if we're on the last day of a month
      final isLastDayOfMonth = columnIndex + 1 < _allDates.length &&
          AppDateUtils.fromDbFormat(_allDates[columnIndex + 1]).day == 1;

      if (isLastDayOfMonth) {
        // Show both current month and next month (e.g., "Sep Oct")
        final currentMonth = _getMonthAbbreviation(leftDate.month);
        final nextDate = AppDateUtils.fromDbFormat(_allDates[columnIndex + 1]);
        final nextMonth = _getMonthAbbreviation(nextDate.month);
        widget.onVisibleMonthChanged('$currentMonth $nextMonth');
        return;
      }

      // Check if the 1st of a month is visible in the first 3 columns (hide sticky if so)
      bool firstOfMonthNearLeft = false;
      for (int i = columnIndex; i < columnIndex + 3 && i < _allDates.length; i++) {
        final date = AppDateUtils.fromDbFormat(_allDates[i]);
        if (date.day == 1) {
          firstOfMonthNearLeft = true;
          break;
        }
      }

      // If the inline month label is visible, hide the sticky label
      if (firstOfMonthNearLeft) {
        widget.onVisibleMonthChanged('');
        return;
      }

      // Find the most recent "1st of month" that has passed the left edge
      String? monthToShow;
      for (int i = columnIndex; i >= 0; i--) {
        final date = AppDateUtils.fromDbFormat(_allDates[i]);
        if (date.day == 1) {
          monthToShow = _getMonthAbbreviation(date.month);
          break;
        }
      }

      // If no 1st of month found (we're before the first one), use the first date's month
      if (monthToShow == null && columnIndex < _allDates.length) {
        monthToShow = _getMonthAbbreviation(leftDate.month);
      }

      if (monthToShow != null) {
        widget.onVisibleMonthChanged(monthToShow);
      }
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    // Check if date range changed and update if needed
    _initializeData();

    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    // Get accent color
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    // Calculate date range for building the dates list
    final endDate = DateTime.now();
    final startDate = DateTime.now().subtract(const Duration(days: 90));

    return FutureBuilder<List<Timeslot>>(
      future: _timeslotsFuture,
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

        // Store dates for scroll tracking
        _allDates = dates;

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
          child: Stack(
            children: [
              // Main scrollable heatmap - fixed width showing 14 days
              SizedBox(
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
              ),
              // Sticky month label overlay
              if (widget.currentVisibleMonth.isNotEmpty)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    height: 12,
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                    ),
                    child: Text(
                      widget.currentVisibleMonth, // Can be "Sep" or "Sep Oct"
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
            ],
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
    final isFirstOfMonth = dateObj.day == 1;

    return GestureDetector(
      onTap: () {
        // Update selected date
        ref.read(selectedDateProvider.notifier).selectDate(dateObj);
        // Navigate back to home screen
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: EdgeInsets.only(right: AppTheme.spacing1),
        child: SizedBox(
          width: 20, // Fixed width for consistent spacing
          child: Column(
            children: [
            // Month label (only show on 1st of month)
            SizedBox(
              height: 12,
              child: isFirstOfMonth
                  ? Text(
                      _getMonthAbbreviation(dateObj.month),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : null,
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
}
