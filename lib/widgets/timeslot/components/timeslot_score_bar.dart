import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import 'description_indicator.dart';
import 'score_badge.dart';

/// The main interactive score bar for a timeslot
/// Handles display of score color, badge, and description
class TimeslotScoreBar extends StatelessWidget {
  final int displayScore;
  final String? description;
  final bool isFuture;
  final Color scoreColor;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;

  const TimeslotScoreBar({
    super.key,
    required this.displayScore,
    required this.description,
    required this.isFuture,
    required this.scoreColor,
    this.onTap,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragStart: isFuture ? null : onDragStart,
      onHorizontalDragUpdate: isFuture ? null : onDragUpdate,
      onHorizontalDragEnd: isFuture ? null : onDragEnd,
      onTap: isFuture ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isFuture
              ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
              : scoreColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: AppSpacing.borderWidth,
          ),
        ),
        child: Stack(
          children: [
            if (displayScore > 0)
              Positioned(
                left: AppSpacing.spacing2,
                top: 0,
                bottom: 0,
                child: Center(child: ScoreBadge(score: displayScore)),
              ),
            if (description != null && description!.isNotEmpty)
              Positioned(
                left: displayScore > 0 ? 60 : AppSpacing.spacing2,
                top: 0,
                bottom: 0,
                right: AppSpacing.spacing2,
                child: Center(
                  child: DescriptionIndicator(description: description!),
                ),
              ),
            if (displayScore == 0 &&
                (description == null || description!.isEmpty) &&
                !isFuture)
              Center(
                child: Text(
                  'Drag to score • Tap to add note',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
