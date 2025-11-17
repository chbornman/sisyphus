import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';

/// Displays the numeric score badge inside a timeslot
/// Fixed width container to prevent layout shifts
class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing2,
        vertical: AppSpacing.spacing1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: AppSpacing.borderWidth,
        ),
      ),
      child: SizedBox(
        width: 32, // Fixed width to accommodate "100"
        child: Text(
          score.toString(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
