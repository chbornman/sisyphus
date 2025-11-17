import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_status.dart';

/// Card widget displaying notification system health and status
class NotificationStatusCard extends StatelessWidget {
  final NotificationStatus status;
  final VoidCallback? onFixTapped;
  final VoidCallback? onDetailsTapped;

  const NotificationStatusCard({
    super.key,
    required this.status,
    this.onFixTapped,
    this.onDetailsTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: status.health.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with health indicator
            Row(
              children: [
                Icon(
                  status.health.icon,
                  color: status.health.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status.health.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: status.health.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (status.health == NotificationHealth.unhealthy && onFixTapped != null)
                  TextButton(
                    onPressed: onFixTapped,
                    style: TextButton.styleFrom(
                      backgroundColor: status.health.color.withOpacity(0.1),
                      foregroundColor: status.health.color,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Fix'),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Status details
            _buildDetailRow(
              context,
              icon: Icons.notifications_active,
              label: 'Scheduled',
              value: '${status.scheduledCount} notifications',
              valueColor: status.scheduledCount > 0 ? null : Colors.orange,
            ),

            if (status.nextNotificationTime != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.schedule,
                label: 'Next',
                value: _formatNextTime(status.nextNotificationTime!),
              ),
            ],

            if (status.lastScheduledAt != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                icon: Icons.update,
                label: 'Updated',
                value: _formatRelativeTime(status.lastScheduledAt!),
                valueColor: _getUpdateTimeColor(status.lastScheduledAt!),
              ),
            ],

            // Error message if present
            if (status.lastError != null && status.lastError!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatError(status.lastError!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (onDetailsTapped != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onDetailsTapped,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View Details'),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatNextTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours} hr';
    } else {
      final formatter = DateFormat('MMM d, h:mm a');
      return formatter.format(time);
    }
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Color? _getUpdateTimeColor(DateTime lastUpdate) {
    final hoursSinceUpdate = DateTime.now().difference(lastUpdate).inHours;

    if (hoursSinceUpdate < 1) {
      return Colors.green;
    } else if (hoursSinceUpdate < 24) {
      return null; // Default color
    } else {
      return Colors.orange;
    }
  }

  String _formatError(String error) {
    // Simplify common error messages
    if (error.contains('timezone')) {
      return 'Timezone configuration issue';
    } else if (error.contains('permission')) {
      return 'Permission denied';
    } else if (error.contains('Location')) {
      return 'Invalid timezone setting';
    } else {
      // Return first line of error only
      return error.split('\n').first;
    }
  }
}