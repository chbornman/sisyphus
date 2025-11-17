import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/timeslot.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/selected_date_provider.dart';
import '../../../providers/scroll_target_provider.dart';
import '../../../providers/settings_provider.dart';

/// Heatmap visualization widget showing happiness patterns over time
/// Separate widget to prevent unnecessary rebuilds when carousel state changes
class HeatmapWidget extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final bool hasScrolledToToday;
  final VoidCallback onScrollComplete;

  const HeatmapWidget({
    super.key,
    required this.scrollController,
    required this.hasScrolledToToday,
    required this.onScrollComplete,
  });

  @override
  ConsumerState<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends ConsumerState<HeatmapWidget> {
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
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
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
        padding: EdgeInsets.only(right: AppSpacing.spacing1),
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
              SizedBox(height: AppSpacing.spacing1),

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
                  margin: const EdgeInsets.only(bottom: 0.5),
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
