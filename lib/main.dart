import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';

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

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Auto-reschedule notifications on app startup if enabled
  // This ensures the 7-day notification window keeps rolling forward
  await _autoRescheduleNotifications(notificationService);

  // Run app with Riverpod
  runApp(const ProviderScope(child: SisyphusApp()));
}

/// Automatically reschedule notifications on app startup if enabled
/// This keeps the 7-day notification window rolling forward as users open the app
Future<void> _autoRescheduleNotifications(NotificationService notificationService) async {
  try {
    final databaseService = DatabaseService();
    final settings = await databaseService.getSettings();

    if (settings.notificationsEnabled) {
      debugPrint('🔄 Auto-rescheduling notifications on app startup...');

      // Check if permission is still granted
      final hasPermission = await notificationService.areNotificationsPermitted();

      if (hasPermission) {
        // Reschedule for the next 7 days
        await notificationService.scheduleNotifications(
          startIndex: settings.notificationStartHour,
          endIndex: settings.notificationEndHour,
        );
        debugPrint('✅ Auto-reschedule complete');
      } else {
        debugPrint('⚠️  Notification permissions revoked, skipping reschedule');
        // Could optionally disable notifications in settings here
      }
    }
  } catch (e) {
    debugPrint('❌ Error during auto-reschedule: $e');
    // Don't crash the app if rescheduling fails
  }
}
