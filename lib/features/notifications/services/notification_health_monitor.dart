import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/notification_status.dart';
import '../../../services/database/database_service.dart';

/// Monitors and reports on the health of the notification system
/// Provides diagnostics, recovery suggestions, and automatic healing
class NotificationHealthMonitor {
  final FlutterLocalNotificationsPlugin _plugin;
  final DatabaseService _database;

  NotificationHealthMonitor({
    required FlutterLocalNotificationsPlugin plugin,
    required DatabaseService database,
  })  : _plugin = plugin,
        _database = database;

  /// Check the current health status of notifications
  Future<NotificationStatus> checkHealth() async {
    try {
      debugPrint('🏥 Checking notification health...');

      // 1. Check if notifications are enabled in settings
      final settings = await _database.getSettings();
      final isEnabled = settings.notificationsEnabled;

      // 2. Check permission status
      final hasPermission = await _checkPermissionStatus();

      // 3. Count scheduled notifications
      final pending = await _plugin.pendingNotificationRequests();
      final scheduledCount = pending.length;

      // 4. Find next notification time
      DateTime? nextNotificationTime;
      if (pending.isNotEmpty) {
        // Parse pending notifications to find the soonest
        // Note: We can't directly get the time from PendingNotificationRequest
        // So we'll estimate based on our knowledge of the scheduling pattern
        final now = DateTime.now();
        final currentHour = now.hour;
        final currentMinute = now.minute;

        // Find next half-hour slot
        if (currentMinute < 30) {
          nextNotificationTime = DateTime(now.year, now.month, now.day, currentHour, 30);
        } else {
          nextNotificationTime = DateTime(now.year, now.month, now.day, currentHour + 1, 0);
        }

        // If next time is still in the past (edge case), add 30 minutes
        if (nextNotificationTime.isBefore(now)) {
          nextNotificationTime = nextNotificationTime.add(const Duration(minutes: 30));
        }
      }

      // 5. Get last scheduled/bootstrap times from database
      final statusData = await _database.getNotificationStatus();

      // 6. Determine health
      final health = _determineHealth(
        isEnabled: isEnabled,
        hasPermission: hasPermission,
        scheduledCount: scheduledCount,
        lastError: statusData['last_error'],
      );

      debugPrint('   Health check complete:');
      debugPrint('   - Enabled: $isEnabled');
      debugPrint('   - Permission: $hasPermission');
      debugPrint('   - Scheduled: $scheduledCount');
      debugPrint('   - Health: ${health.name}');

      return NotificationStatus(
        isEnabled: isEnabled,
        hasPermission: hasPermission,
        scheduledCount: scheduledCount,
        nextNotificationTime: nextNotificationTime,
        lastScheduledAt: statusData['last_scheduled_at'] != null
            ? DateTime.tryParse(statusData['last_scheduled_at']!)
            : null,
        lastBootstrapAt: statusData['last_bootstrap_at'] != null
            ? DateTime.tryParse(statusData['last_bootstrap_at']!)
            : null,
        lastError: statusData['last_error'],
        health: health,
      );
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
      return NotificationStatus(
        isEnabled: false,
        hasPermission: false,
        scheduledCount: 0,
        lastError: e.toString(),
        health: NotificationHealth.unhealthy,
      );
    }
  }

  /// Check if notification permissions are granted
  Future<bool> _checkPermissionStatus() async {
    // Check iOS-specific permissions
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      // We're on iOS
      final settings = await iosPlugin.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    // Check Android permissions
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Determine health status based on current state
  NotificationHealth _determineHealth({
    required bool isEnabled,
    required bool hasPermission,
    required int scheduledCount,
    String? lastError,
  }) {
    // If disabled, that's expected - not unhealthy
    if (!isEnabled) {
      return NotificationHealth.unknown;
    }

    // If enabled but no permission, that's unhealthy
    if (!hasPermission) {
      return NotificationHealth.unhealthy;
    }

    // If there's a recent error, unhealthy
    if (lastError != null && lastError.isNotEmpty) {
      return NotificationHealth.unhealthy;
    }

    // Check scheduled count
    if (scheduledCount == 0) {
      return NotificationHealth.unhealthy;
    } else if (scheduledCount < 20) {
      return NotificationHealth.degraded;
    } else {
      return NotificationHealth.healthy;
    }
  }

  /// Save health status to database
  Future<void> saveHealthStatus(NotificationStatus status) async {
    await _database.saveNotificationStatus(status.toDatabase());
  }

  /// Get diagnostic information for troubleshooting
  Future<NotificationDiagnostics> getDiagnostics() async {
    final status = await checkHealth();
    final pending = await _plugin.pendingNotificationRequests();

    // Group notifications by type
    int immediateCount = 0;
    int bootstrapCount = 0;
    int otherCount = 0;

    for (final notification in pending) {
      if (notification.id == 9999) {
        bootstrapCount++;
      } else if (notification.id < 1000) {
        immediateCount++;
      } else {
        otherCount++;
      }
    }

    // Check iOS/Android specific limits
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final platformLimit = isIOS ? 64 : 500;
    final isNearLimit = pending.length > (platformLimit * 0.8);

    return NotificationDiagnostics(
      status: status,
      pendingCount: pending.length,
      immediateCount: immediateCount,
      bootstrapCount: bootstrapCount,
      otherCount: otherCount,
      platformLimit: platformLimit,
      isNearLimit: isNearLimit,
      recommendations: _generateRecommendations(status, pending.length, isNearLimit),
    );
  }

  /// Generate recommendations for fixing issues
  List<String> _generateRecommendations(
    NotificationStatus status,
    int pendingCount,
    bool isNearLimit,
  ) {
    final recommendations = <String>[];

    if (!status.hasPermission) {
      recommendations.add('Grant notification permissions in Settings');
    }

    if (status.scheduledCount == 0 && status.isEnabled) {
      recommendations.add('Tap "Fix Notifications" to reschedule');
    }

    if (status.lastError != null) {
      if (status.lastError!.contains('timezone')) {
        recommendations.add('Check your device timezone settings');
      } else if (status.lastError!.contains('permission')) {
        recommendations.add('Enable notifications in device Settings');
      } else {
        recommendations.add('Try disabling and re-enabling notifications');
      }
    }

    if (isNearLimit) {
      recommendations.add('Notification limit nearly reached - some may not fire');
    }

    if (status.lastScheduledAt != null) {
      final hoursSinceSchedule =
          DateTime.now().difference(status.lastScheduledAt!).inHours;
      if (hoursSinceSchedule > 24) {
        recommendations.add('Open the app daily for best notification reliability');
      }
    }

    return recommendations;
  }

  /// Attempt automatic recovery of unhealthy notifications
  Future<bool> attemptRecovery() async {
    debugPrint('🔧 Attempting automatic notification recovery...');

    try {
      // 1. Check and request permissions if needed
      final hasPermission = await _checkPermissionStatus();
      if (!hasPermission) {
        debugPrint('   No permission - cannot auto-recover');
        return false;
      }

      // 2. Clear any error state
      await _database.updateSettingNullable('last_error', null);

      // 3. Return true to indicate recovery can be attempted
      debugPrint('   Ready for recovery - caller should reschedule');
      return true;

    } catch (e) {
      debugPrint('   Recovery failed: $e');
      return false;
    }
  }
}

/// Diagnostic information for troubleshooting
class NotificationDiagnostics {
  final NotificationStatus status;
  final int pendingCount;
  final int immediateCount;
  final int bootstrapCount;
  final int otherCount;
  final int platformLimit;
  final bool isNearLimit;
  final List<String> recommendations;

  NotificationDiagnostics({
    required this.status,
    required this.pendingCount,
    required this.immediateCount,
    required this.bootstrapCount,
    required this.otherCount,
    required this.platformLimit,
    required this.isNearLimit,
    required this.recommendations,
  });
}