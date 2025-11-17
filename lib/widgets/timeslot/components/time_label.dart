import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/time_utils.dart';
import '../../../models/app_settings.dart';

/// Displays the time label for a timeslot
/// Shows current slot with highlighted background and animation
class TimeLabel extends StatelessWidget {
  final int timeIndex;
  final TimeFormat timeFormat;
  final bool isCurrentSlot;
  final bool isFuture;
  final Color accentColor;
  final Animation<double>? scaleAnimation;
  final Animation<double>? fadeAnimation;
  final AnimationController? animationController;

  const TimeLabel({
    super.key,
    required this.timeIndex,
    required this.timeFormat,
    required this.isCurrentSlot,
    required this.isFuture,
    required this.accentColor,
    this.scaleAnimation,
    this.fadeAnimation,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTime = TimeUtils.formatTimeForDisplay(timeIndex, timeFormat);

    final timeLabel = Text(
      formattedTime,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: isCurrentSlot ? FontWeight.w600 : FontWeight.normal,
        color: isCurrentSlot
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(
                alpha: isFuture ? 0.3 : 0.6,
              ),
      ),
      textAlign: TextAlign.center,
    );

    final content = isCurrentSlot
        ? Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing1,
              vertical: AppSpacing.spacing1,
            ),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
            ),
            child: timeLabel,
          )
        : Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing1),
            child: timeLabel,
          );

    return SizedBox(
      width: timeFormat == TimeFormat.twelveHour ? 75 : 60,
      child: isCurrentSlot && animationController != null
          ? AnimatedBuilder(
              animation: animationController!,
              builder: (context, child) {
                return Transform.scale(
                  scale: scaleAnimation?.value ?? 1.0,
                  child: Opacity(
                    opacity: fadeAnimation?.value ?? 1.0,
                    child: child,
                  ),
                );
              },
              child: content,
            )
          : content,
    );
  }
}
