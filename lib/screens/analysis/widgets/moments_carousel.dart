import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/app_settings.dart';
import '../../../models/timeslot.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import 'moment_card.dart';
import 'time_filter.dart';

/// Carousel widget displaying top or bottom memorable moments
class MomentsCarousel extends ConsumerWidget {
  final bool showTopMoments;
  final TimeFilter selectedTimeFilter;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const MomentsCarousel({
    super.key,
    required this.showTopMoments,
    required this.selectedTimeFilter,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
      DateTime.now().subtract(Duration(days: selectedTimeFilter.days)),
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
          return _buildEmptyState(theme, 'No tracked moments in this timeframe');
        }

        // Show message if fewer than 5 timeslots tracked
        if (allMoments.length < 5) {
          return _buildNotEnoughDataState(theme);
        }

        // Sort and take top/bottom 5
        final moments = showTopMoments
            ? (allMoments..sort((a, b) => b.happinessScore.compareTo(a.happinessScore)))
                .take(5)
                .toList()
            : (allMoments..sort((a, b) => a.happinessScore.compareTo(b.happinessScore)))
                .take(5)
                .toList();

        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: pageController,
            // Use large virtual page count for infinite scroll effect
            itemCount: 10000,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              // Map virtual page index to actual moment using modulo
              final momentIndex = index % moments.length;
              final moment = moments[momentIndex];
              return MomentCard(
                moment: moment,
                accentColor: accentColor,
                timeFormat: timeFormat,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNotEnoughDataState(ThemeData theme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.spacing4),
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
            SizedBox(height: AppSpacing.spacing2),
            Text(
              'Check back once you\'ve logged 5 timeslots',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.spacing1),
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
}
