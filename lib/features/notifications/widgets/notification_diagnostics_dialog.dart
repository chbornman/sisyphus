import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_health_monitor.dart';

/// Dialog showing detailed notification diagnostics
class NotificationDiagnosticsDialog extends StatelessWidget {
  final NotificationDiagnostics diagnostics;
  final VoidCallback? onTestNotification;
  final VoidCallback? onReschedule;

  const NotificationDiagnosticsDialog({
    super.key,
    required this.diagnostics,
    this.onTestNotification,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: diagnostics.status.health.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    diagnostics.status.health.icon,
                    color: diagnostics.status.health.color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Diagnostics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          diagnostics.status.health.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: diagnostics.status.health.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notification counts
                    _buildSection(
                      context,
                      title: 'Notification Breakdown',
                      children: [
                        _buildStatRow('Total Pending', '${diagnostics.pendingCount}'),
                        _buildStatRow('Immediate (48hr)', '${diagnostics.immediateCount}'),
                        _buildStatRow('Daily Bootstrap', '${diagnostics.bootstrapCount}'),
                        if (diagnostics.otherCount > 0)
                          _buildStatRow('Other', '${diagnostics.otherCount}'),
                        const Divider(height: 16),
                        _buildStatRow(
                          'Platform Limit',
                          '${diagnostics.pendingCount} / ${diagnostics.platformLimit}',
                          valueColor: diagnostics.isNearLimit ? Colors.orange : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // System info
                    _buildSection(
                      context,
                      title: 'System Information',
                      children: [
                        _buildStatRow(
                          'Notifications Enabled',
                          diagnostics.status.isEnabled ? 'Yes' : 'No',
                          valueColor: diagnostics.status.isEnabled ? Colors.green : Colors.red,
                        ),
                        _buildStatRow(
                          'Has Permission',
                          diagnostics.status.hasPermission ? 'Granted' : 'Denied',
                          valueColor: diagnostics.status.hasPermission ? Colors.green : Colors.red,
                        ),
                        if (diagnostics.status.lastScheduledAt != null)
                          _buildStatRow(
                            'Last Scheduled',
                            _formatDateTime(diagnostics.status.lastScheduledAt!),
                          ),
                        if (diagnostics.status.lastBootstrapAt != null)
                          _buildStatRow(
                            'Last Bootstrap',
                            _formatDateTime(diagnostics.status.lastBootstrapAt!),
                          ),
                      ],
                    ),

                    // Recommendations
                    if (diagnostics.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        context,
                        title: 'Recommendations',
                        children: diagnostics.recommendations
                            .map((rec) => _buildRecommendation(context, rec))
                            .toList(),
                      ),
                    ],

                    // Error details
                    if (diagnostics.status.lastError != null) ...[
                      const SizedBox(height: 16),
                      _buildSection(
                        context,
                        title: 'Error Details',
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    diagnostics.status.lastError!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: diagnostics.status.lastError!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Error copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Copy error',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onTestNotification != null)
                    TextButton.icon(
                      onPressed: () {
                        onTestNotification!();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.science, size: 16),
                      label: const Text('Test'),
                    ),
                  const SizedBox(width: 8),
                  if (onReschedule != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        onReschedule!();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reschedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}