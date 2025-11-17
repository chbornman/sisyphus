import 'package:flutter/material.dart';

/// Model for tracking notification system health and status
class NotificationStatus {
  final bool isEnabled;
  final bool hasPermission;
  final int scheduledCount;
  final DateTime? nextNotificationTime;
  final DateTime? lastScheduledAt;
  final DateTime? lastBootstrapAt;
  final String? lastError;
  final NotificationHealth health;

  const NotificationStatus({
    required this.isEnabled,
    required this.hasPermission,
    required this.scheduledCount,
    this.nextNotificationTime,
    this.lastScheduledAt,
    this.lastBootstrapAt,
    this.lastError,
    required this.health,
  });

  /// Create an initial/unknown status
  factory NotificationStatus.unknown() {
    return const NotificationStatus(
      isEnabled: false,
      hasPermission: false,
      scheduledCount: 0,
      health: NotificationHealth.unknown,
    );
  }

  /// Create from database values
  factory NotificationStatus.fromDatabase(Map<String, dynamic> data) {
    return NotificationStatus(
      isEnabled: data['notifications_enabled'] == 'true',
      hasPermission: data['has_permission'] == 'true',
      scheduledCount: int.tryParse(data['scheduled_count'] ?? '0') ?? 0,
      nextNotificationTime: data['next_notification_time'] != null
        ? DateTime.tryParse(data['next_notification_time'])
        : null,
      lastScheduledAt: data['last_scheduled_at'] != null
        ? DateTime.tryParse(data['last_scheduled_at'])
        : null,
      lastBootstrapAt: data['last_bootstrap_at'] != null
        ? DateTime.tryParse(data['last_bootstrap_at'])
        : null,
      lastError: data['last_error'],
      health: NotificationHealth.fromScheduledCount(
        int.tryParse(data['scheduled_count'] ?? '0') ?? 0,
        data['last_error'],
      ),
    );
  }

  /// Convert to database format
  Map<String, String> toDatabase() {
    return {
      'notifications_enabled': isEnabled.toString(),
      'has_permission': hasPermission.toString(),
      'scheduled_count': scheduledCount.toString(),
      if (nextNotificationTime != null)
        'next_notification_time': nextNotificationTime!.toIso8601String(),
      if (lastScheduledAt != null)
        'last_scheduled_at': lastScheduledAt!.toIso8601String(),
      if (lastBootstrapAt != null)
        'last_bootstrap_at': lastBootstrapAt!.toIso8601String(),
      if (lastError != null) 'last_error': lastError!,
    };
  }

  NotificationStatus copyWith({
    bool? isEnabled,
    bool? hasPermission,
    int? scheduledCount,
    DateTime? nextNotificationTime,
    DateTime? lastScheduledAt,
    DateTime? lastBootstrapAt,
    String? lastError,
    NotificationHealth? health,
  }) {
    return NotificationStatus(
      isEnabled: isEnabled ?? this.isEnabled,
      hasPermission: hasPermission ?? this.hasPermission,
      scheduledCount: scheduledCount ?? this.scheduledCount,
      nextNotificationTime: nextNotificationTime ?? this.nextNotificationTime,
      lastScheduledAt: lastScheduledAt ?? this.lastScheduledAt,
      lastBootstrapAt: lastBootstrapAt ?? this.lastBootstrapAt,
      lastError: lastError,  // Allow clearing error by passing null
      health: health ?? this.health,
    );
  }
}

/// Health status of the notification system
enum NotificationHealth {
  /// Everything working perfectly
  healthy,

  /// Some notifications scheduled but not optimal
  degraded,

  /// No notifications scheduled or errors present
  unhealthy,

  /// Status unknown (initial state)
  unknown;

  /// Determine health from scheduled count and errors
  static NotificationHealth fromScheduledCount(int count, String? error) {
    if (error != null) return NotificationHealth.unhealthy;
    if (count == 0) return NotificationHealth.unhealthy;
    if (count < 20) return NotificationHealth.degraded;
    return NotificationHealth.healthy;
  }

  /// Get color for UI display
  Color get color {
    switch (this) {
      case NotificationHealth.healthy:
        return const Color(0xFF4CAF50); // Green
      case NotificationHealth.degraded:
        return const Color(0xFFFF9800); // Orange
      case NotificationHealth.unhealthy:
        return const Color(0xFFF44336); // Red
      case NotificationHealth.unknown:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get icon for UI display
  IconData get icon {
    switch (this) {
      case NotificationHealth.healthy:
        return Icons.check_circle;
      case NotificationHealth.degraded:
        return Icons.warning;
      case NotificationHealth.unhealthy:
        return Icons.error;
      case NotificationHealth.unknown:
        return Icons.help_outline;
    }
  }

  /// Get human-readable description
  String get description {
    switch (this) {
      case NotificationHealth.healthy:
        return 'All notifications scheduled';
      case NotificationHealth.degraded:
        return 'Some notifications scheduled';
      case NotificationHealth.unhealthy:
        return 'Notifications not working';
      case NotificationHealth.unknown:
        return 'Checking notification status...';
    }
  }
}