import 'package:flutter/material.dart';

/// Displays the description text preview for a timeslot
/// Truncates long descriptions with ellipsis
class DescriptionIndicator extends StatelessWidget {
  final String description;

  const DescriptionIndicator({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      description,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
        height: 1.4, // Slightly tighter line height for better fit
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
