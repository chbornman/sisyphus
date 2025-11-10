import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:sisyphus/core/utils/time_utils.dart';
import 'package:sisyphus/models/app_settings.dart';

/// Service for managing local notifications
/// Handles scheduling, permissions, and half-hourly happiness tracking reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  /// Sets up platform-specific configuration and channels
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️  NotificationService already initialized');
      return;
    }

    debugPrint('🚀 Initializing NotificationService...');

    // Android-specific initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS-specific initialization settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually for better UX
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    // Initialize plugin with callback for when user taps notification
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized successfully');
  }

  /// Called when user taps on a notification
  /// Opens the app to the home screen
  void _onNotificationTapped(NotificationResponse response) {
    // The app will automatically open to the home screen
    // Additional navigation logic can be added here if needed
  }

  /// Request notification permissions (iOS requires explicit permission)
  /// Returns true if permission granted, false otherwise
  Future<bool> requestPermissions() async {
    debugPrint('🔔 Requesting notification permissions...');

    // iOS-specific permission request (must be called first on iOS)
    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      // We're on iOS - request permissions through the plugin
      final bool? result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = result ?? false;
      debugPrint(granted
          ? '✅ Notification permissions granted (iOS)'
          : '❌ Notification permissions denied (iOS)');
      return granted; // If result is null, something went wrong
    }

    // On Android 13+, need to request permission
    final status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      debugPrint('❌ Notification permissions denied (Android)');
      return false;
    }

    debugPrint('✅ Notification permissions granted (Android)');
    return true; // Permission granted on Android
  }

  /// Check if notifications are currently permitted
  Future<bool> areNotificationsPermitted() async {
    if (await Permission.notification.isPermanentlyDenied) {
      return false;
    }

    return await Permission.notification.isGranted;
  }

  /// Schedule half-hourly notifications within the specified time range
  /// startIndex and endIndex are 0-47 representing 30-minute timeslots
  /// Schedules notifications for the next 7 days
  Future<void> scheduleNotifications({
    required int startIndex,
    required int endIndex,
  }) async {
    if (!_isInitialized) {
      throw StateError('NotificationService not initialized');
    }

    // Validate indices
    if (startIndex < 0 || startIndex > 47 || endIndex < 0 || endIndex > 47) {
      throw ArgumentError('Time indices must be between 0 and 47');
    }

    if (startIndex >= endIndex) {
      throw ArgumentError('Start index must be before end index');
    }

    // Log notification scheduling start with time range
    final startTime = TimeUtils.formatTimeForDisplay(startIndex, TimeFormat.twelveHour);
    final endTime = TimeUtils.formatTimeForDisplay(endIndex, TimeFormat.twelveHour);
    debugPrint('📅 Starting notification setup...');
    debugPrint('   Time range: $startTime - $endTime');
    debugPrint('   Duration: 7 days, ${endIndex - startIndex} slots per day');

    // Cancel existing notifications first
    await cancelAllNotifications();

    // Schedule notifications for the next 7 days
    final now = tz.TZDateTime.now(tz.local);
    int scheduledCount = 0;

    for (int day = 0; day < 7; day++) {
      final targetDate = now.add(Duration(days: day));

      // Schedule each half-hour slot within the time range
      for (int timeIndex = startIndex; timeIndex < endIndex; timeIndex++) {
        // Calculate hour and minute from time index
        final hour = timeIndex ~/ 2;
        final minute = (timeIndex % 2) * 30;

        var scheduledTime = tz.TZDateTime(
          tz.local,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        // Only schedule if the time is in the future
        if (scheduledTime.isAfter(now)) {
          await _scheduleNotification(
            id: _generateNotificationId(day, timeIndex),
            scheduledTime: scheduledTime,
            timeIndex: timeIndex,
          );
          scheduledCount++;
        }
      }
    }

    debugPrint('✅ Notification setup complete: $scheduledCount notifications scheduled');
  }

  /// Schedule a single notification at a specific time
  Future<void> _scheduleNotification({
    required int id,
    required tz.TZDateTime scheduledTime,
    required int timeIndex,
  }) async {
    final timeString = TimeUtils.formatTimeForDisplay(
      timeIndex,
      TimeFormat.twelveHour,
    );

    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'happiness_reminders', // Channel ID
      'Happiness Reminders', // Channel name
      channelDescription: 'Half-hourly reminders to track your happiness',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    // iOS notification details
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'happiness_reminder',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notifications.zonedSchedule(
      id,
      'Time to track your happiness!',
      'How are you feeling right now? ($timeString)',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Generate unique notification ID from day offset and time index
  /// ID format: DTTTT where D is day (0-6) and TTTT is time index (0-47)
  int _generateNotificationId(int dayOffset, int timeIndex) {
    return (dayOffset * 100) + timeIndex;
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    debugPrint('🔕 Cancelling all scheduled notifications...');
    await _notifications.cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    await _notifications.cancel(id);
  }

  /// Get list of all pending notification requests (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    return await _notifications.pendingNotificationRequests();
  }

  /// Reschedule notifications with new time range
  /// Convenience method that cancels and reschedules
  Future<void> rescheduleNotifications({
    required int startIndex,
    required int endIndex,
  }) async {
    final startTime = TimeUtils.formatTimeForDisplay(startIndex, TimeFormat.twelveHour);
    final endTime = TimeUtils.formatTimeForDisplay(endIndex, TimeFormat.twelveHour);
    debugPrint('🔄 Rescheduling notifications with new time range: $startTime - $endTime');

    await scheduleNotifications(
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }
}
