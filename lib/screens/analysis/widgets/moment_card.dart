import 'package:flutter/material.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/time_utils.dart';
import '../../../models/app_settings.dart';
import '../../../models/timeslot.dart';

/// Individual moment card widget for the moments carousel
class MomentCard extends StatelessWidget {
  final Timeslot moment;
  final Color accentColor;
  final TimeFormat timeFormat;

  const MomentCard({
    super.key,
    required this.moment,
    required this.accentColor,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = ColorUtils.getTimeslotColor(accentColor, moment.happinessScore);
    final formattedTime = TimeUtils.formatTimeForDisplay(moment.timeIndex, timeFormat);
    final formattedDate = AppDateUtils.toDisplayFormat(
      AppDateUtils.fromDbFormat(moment.date),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
      padding: EdgeInsets.all(AppSpacing.spacing3),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: scoreColor.a * 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
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
          SizedBox(height: AppSpacing.spacing2),

          // Description - prominent display
          if (moment.description != null && moment.description!.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
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

          SizedBox(height: AppSpacing.spacing2),

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
}
