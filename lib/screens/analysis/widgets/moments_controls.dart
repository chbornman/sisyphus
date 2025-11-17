import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import 'time_filter.dart';

/// Controls for filtering memorable moments (top/bottom toggle + time filter)
class MomentsControls extends StatelessWidget {
  final bool showTopMoments;
  final TimeFilter selectedTimeFilter;
  final ValueChanged<bool> onMomentsToggleChanged;
  final ValueChanged<TimeFilter> onTimeFilterChanged;

  const MomentsControls({
    super.key,
    required this.showTopMoments,
    required this.selectedTimeFilter,
    required this.onMomentsToggleChanged,
    required this.onTimeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              selected: {showTopMoments},
              onSelectionChanged: (Set<bool> newSelection) {
                onMomentsToggleChanged(newSelection.first);
              },
            ),
          ),
          SizedBox(width: AppSpacing.spacing1),
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
              selected: {selectedTimeFilter},
              onSelectionChanged: (Set<TimeFilter> newSelection) {
                onTimeFilterChanged(newSelection.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}
