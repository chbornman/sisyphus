import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../services/database_service.dart';
import 'enhanced_notification_service.dart';
import '../models/notification_status.dart';

/// Background task handler for WorkManager
///
/// This runs periodically to ensure notifications remain scheduled
/// even if the app hasn't been opened in several days
class BackgroundTaskHandler {
  static const String taskName = 'notification-refresh';
  static const String uniqueName = 'sisyphus-notification-refresh';

  /// Initialize WorkManager for background tasks (Android only)
  static Future<void> initialize() async {
    // WorkManager is Android-only - skip on iOS
    if (!kIsWeb && Platform.isAndroid) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      debugPrint('🔧 WorkManager initialized');
    } else {
      debugPrint('ℹ️  WorkManager skipped (iOS/Web platform)');
    }
  }

  /// Register periodic task to refresh notifications (Android only)
  static Future<void> registerPeriodicTask() async {
    // Only register on Android
    if (!kIsWeb && Platform.isAndroid) {
      try {
        // Cancel existing task if any
        await Workmanager().cancelByUniqueName(uniqueName);

        // Register new periodic task
        // Runs every 12 hours (minimum is 15 minutes on Android)
        await Workmanager().registerPeriodicTask(
        uniqueName,
        taskName,
        frequency: const Duration(hours: 12),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 30),
      );

        debugPrint('✅ Background task registered: runs every 12 hours');
      } catch (e) {
        debugPrint('❌ Failed to register background task: $e');
      }
    } else {
      debugPrint('ℹ️  Background task registration skipped (iOS/Web)');
    }
  }

  /// Cancel background task (Android only)
  static Future<void> cancelTask() async {
    if (!kIsWeb && Platform.isAndroid) {
      await Workmanager().cancelByUniqueName(uniqueName);
      debugPrint('🔕 Background task cancelled');
    }
  }
}

/// Top-level callback function for WorkManager
/// Must be top-level or static to be accessible from background isolate
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🌙 Background task started: $task');

    try {
      // Initialize timezone for background isolate
      tz.initializeTimeZones();

      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final timeZoneName = timezoneInfo.identifier;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('⚠️  Using UTC in background: $e');
        tz.setLocalLocation(tz.UTC);
      }

      // Only handle our specific task
      if (task == BackgroundTaskHandler.taskName) {
        await _performNotificationRefresh();
      }

      debugPrint('✅ Background task completed');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

/// Perform the actual notification refresh in background
Future<void> _performNotificationRefresh() async {
  debugPrint('🔄 Refreshing notifications in background...');

  try {
    // Initialize services
    final database = DatabaseService();
    final notificationService = EnhancedNotificationService();
    await notificationService.initialize();

    // Get current settings
    final settings = await database.getSettings();

    if (!settings.notificationsEnabled) {
      debugPrint('   Notifications disabled - skipping refresh');
      return;
    }

    // Check current health
    final healthStatus = await notificationService.performHealthCheck();
    debugPrint('   Current health: ${healthStatus.health.name}');
    debugPrint('   Scheduled count: ${healthStatus.scheduledCount}');

    // Determine if refresh is needed
    bool needsRefresh = false;

    // Check if unhealthy
    if (healthStatus.health == NotificationHealth.unhealthy) {
      debugPrint('   Unhealthy - needs refresh');
      needsRefresh = true;
    }

    // Check if too few notifications scheduled
    if (healthStatus.scheduledCount < 20) {
      debugPrint('   Low notification count - needs refresh');
      needsRefresh = true;
    }

    // Check if last scheduled was too long ago
    if (healthStatus.lastScheduledAt != null) {
      final hoursSinceSchedule =
          DateTime.now().difference(healthStatus.lastScheduledAt!).inHours;

      if (hoursSinceSchedule > 24) {
        debugPrint('   Last scheduled ${hoursSinceSchedule}h ago - needs refresh');
        needsRefresh = true;
      }
    } else {
      // Never scheduled
      needsRefresh = true;
    }

    if (needsRefresh) {
      debugPrint('   Rescheduling notifications...');

      // Attempt recovery if unhealthy
      if (healthStatus.health == NotificationHealth.unhealthy) {
        await notificationService.attemptRecovery();
      }

      // Reschedule notifications
      final newStatus = await notificationService.scheduleNotifications(
        startIndex: settings.notificationStartHour,
        endIndex: settings.notificationEndHour,
        enabled: true,
      );

      debugPrint('   Rescheduled: ${newStatus.scheduledCount} notifications');
      debugPrint('   New health: ${newStatus.health.name}');

      // Save timestamp
      await database.updateSetting(
        'last_background_refresh',
        DateTime.now().toIso8601String(),
      );
    } else {
      debugPrint('   No refresh needed - notifications healthy');
    }
  } catch (e) {
    debugPrint('❌ Background refresh failed: $e');
  }
}