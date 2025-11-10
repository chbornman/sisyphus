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

/// Analysis screen - Heatmap and insights view
/// Visualizes happiness patterns and highlights top/bottom moments
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  // Date range options
  int _selectedDays = 7; // Default to last 7 days

  // Moments toggle (true = top moments, false = bottom moments)
  bool _showTopMoments = true;

  // Carousel auto-advance
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startCarouselAutoAdvance();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
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
          _currentCarouselPage = (_currentCarouselPage + 1) % 10; // Max 10 moments
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
            // Date range selector
            _buildDateRangeSelector(theme),
            SizedBox(height: AppTheme.spacing6),

            // Heatmap section
            _buildSectionHeader('Happiness Patterns', theme),
            SizedBox(height: AppTheme.spacing3),
            _buildHeatmap(theme),
            SizedBox(height: AppTheme.spacing6),

            // Moments carousel section
            _buildSectionHeader('Memorable Moments', theme),
            SizedBox(height: AppTheme.spacing3),
            _buildMomentsToggle(theme),
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

  /// Build date range selector chips
  Widget _buildDateRangeSelector(ThemeData theme) {
    return Wrap(
      spacing: AppTheme.spacing2,
      children: [
        _buildRangeChip('7 days', 7, theme),
        _buildRangeChip('14 days', 14, theme),
        _buildRangeChip('30 days', 30, theme),
        _buildRangeChip('All time', -1, theme),
      ],
    );
  }

  Widget _buildRangeChip(String label, int days, ThemeData theme) {
    final isSelected = _selectedDays == days;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDays = days;
          });
        }
      },
    );
  }

  /// Build heatmap visualization
  Widget _buildHeatmap(ThemeData theme) {
    final dbService = ref.watch(databaseServiceProvider);
    final settingsAsync = ref.watch(settingsProvider);

    // Get accent color
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    // Calculate date range
    final endDate = DateTime.now();
    final startDate = _selectedDays == -1
        ? DateTime.now().subtract(const Duration(days: 90)) // Cap at 90 days for "all time"
        : endDate.subtract(Duration(days: _selectedDays - 1));

    final dateRangeStart = AppDateUtils.toDbFormat(startDate);
    final dateRangeEnd = AppDateUtils.toDbFormat(endDate);

    return FutureBuilder<List<Timeslot>>(
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

        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(AppTheme.spacing2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time labels column
                _buildTimeLabelsColumn(theme),
                SizedBox(width: AppTheme.spacing1),

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

  /// Build time labels column (00:00, 00:30, etc.)
  Widget _buildTimeLabelsColumn(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(48, (index) {
        // Only show labels every 4 slots (every 2 hours) to save space
        if (index % 4 == 0) {
          final timeStr = TimeUtils.indexToTime(index);
          return SizedBox(
            height: 5, // Tiny row height
            child: Text(
              timeStr,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }
        return const SizedBox(height: 5);
      }),
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

    return Padding(
      padding: EdgeInsets.only(right: AppTheme.spacing1),
      child: Column(
        children: [
          // Date header (abbreviated)
          Text(
            AppDateUtils.fromDbFormat(date).day.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
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
    );
  }

  /// Build toggle between top/bottom moments
  Widget _buildMomentsToggle(ThemeData theme) {
    return Center(
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: true,
            label: Text('Top 10'),
            icon: Icon(Icons.sentiment_very_satisfied),
          ),
          ButtonSegment(
            value: false,
            label: Text('Bottom 10'),
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

    // Calculate date range
    final endDate = AppDateUtils.toDbFormat(DateTime.now());
    final startDate = _selectedDays == -1
        ? '2000-01-01' // All time
        : AppDateUtils.toDbFormat(
            DateTime.now().subtract(Duration(days: _selectedDays - 1)),
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

        // Sort and take top/bottom 10
        final moments = _showTopMoments
            ? (allMoments..sort((a, b) => b.happinessScore.compareTo(a.happinessScore)))
                .take(10)
                .toList()
            : (allMoments..sort((a, b) => a.happinessScore.compareTo(b.happinessScore)))
                .take(10)
                .toList();

        return SizedBox(
          height: 220,
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
      padding: EdgeInsets.all(AppTheme.spacing4),
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
            padding: EdgeInsets.all(AppTheme.spacing3),
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              moment.happinessScore.toString(),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacing3),

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

          // Description (if exists)
          if (moment.description != null && moment.description!.isNotEmpty) ...[
            SizedBox(height: AppTheme.spacing2),
            Text(
              moment.description!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
