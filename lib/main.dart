import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'app.dart';
import 'features/notifications/services/enhanced_notification_service.dart';
import 'features/notifications/services/background_task_handler.dart';
import 'features/notifications/models/notification_status.dart';
import 'services/database/database_service.dart';

/// Application entry point
/// Initializes Riverpod state management and starts the app
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database for notification scheduling
  tz.initializeTimeZones();

  // Get the device's local timezone using flutter_timezone
  // This ensures notifications are scheduled in the user's actual local time
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint('✅ Timezone set to: $timeZoneName');
  } catch (e) {
    debugPrint('⚠️  Error getting device timezone, using UTC: $e');
    // Fallback to UTC if we can't determine local timezone
    tz.setLocalLocation(tz.UTC);
  }

  // Initialize enhanced notification service
  final notificationService = EnhancedNotificationService();
  await notificationService.initialize();

  // Initialize background task handler
  await BackgroundTaskHandler.initialize();

  // Auto-reschedule notifications on app startup if enabled
  // This ensures notifications keep working with our new tiered strategy
  await _autoRescheduleNotifications(notificationService);

  // Run app with Riverpod
  runApp(const ProviderScope(child: SisyphusApp()));
}

/// Automatically reschedule notifications on app startup if enabled
/// Uses enhanced service with health monitoring and automatic recovery
Future<void> _autoRescheduleNotifications(EnhancedNotificationService notificationService) async {
  try {
    final databaseService = DatabaseService();
    final settings = await databaseService.getSettings();

    if (settings.notificationsEnabled) {
      debugPrint('🔄 Auto-rescheduling notifications on app startup...');

      // First check health status
      final healthStatus = await notificationService.performHealthCheck();
      debugPrint('   Current health: ${healthStatus.health.name}');

      // If unhealthy, attempt recovery
      if (healthStatus.health == NotificationHealth.unhealthy) {
        debugPrint('🔧 Attempting automatic recovery...');
        final recovered = await notificationService.attemptRecovery();

        if (!recovered) {
          debugPrint('⚠️  Recovery failed - notifications may need manual fix');
          return;
        }
      }

      // Schedule notifications using enhanced tiered strategy
      final status = await notificationService.scheduleNotifications(
        startIndex: settings.notificationStartHour,
        endIndex: settings.notificationEndHour,
        enabled: true,
      );

      debugPrint('✅ Auto-reschedule complete: ${status.scheduledCount} notifications');

      // Log final health status
      if (status.health != NotificationHealth.healthy) {
        debugPrint('⚠️  Health status: ${status.health.name}');
        if (status.lastError != null) {
          debugPrint('   Error: ${status.lastError}');
        }
      }

      // Register background task to keep notifications working
      await BackgroundTaskHandler.registerPeriodicTask();
    } else {
      // Notifications disabled - cancel background task
      await BackgroundTaskHandler.cancelTask();
    }
  } catch (e) {
    debugPrint('❌ Error during auto-reschedule: $e');
    // Don't crash the app if rescheduling fails
  }
}
