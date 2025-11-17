import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/utils/time_utils.dart';
import '../../../models/app_settings.dart';
import '../models/notification_status.dart';

/// Core notification scheduling service implementing tiered strategy
///
/// Tier 1: Immediate notifications (next 24-48 hours)
/// Tier 2: Daily recurring notification for bootstrap
/// Tier 3: Background refresh as safety net
class NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;

  // Platform limits
  static const int _iosNotificationLimit = 64;
  static const int _androidNotificationLimit = 500;

  // Our conservative limits for reliability
  static const int _maxImmediateNotifications = 40;
  static const int _immediateHoursAhead = 48; // Schedule 48 hours ahead
  static const int _bootstrapNotificationId = 9999; // Reserved ID for daily bootstrap

  NotificationScheduler(this._plugin);

  /// Schedule notifications using tiered strategy
  /// Returns NotificationStatus with results
  Future<NotificationStatus> scheduleNotifications({
    required int startHourIndex,
    required int endHourIndex,
    required bool isEnabled,
  }) async {
    try {
      debugPrint('🚀 Starting tiered notification scheduling...');
      debugPrint('   Time range: ${TimeUtils.formatTimeForDisplay(startHourIndex, TimeFormat.twelveHour)} - ${TimeUtils.formatTimeForDisplay(endHourIndex, TimeFormat.twelveHour)}');

      // Clear all existing notifications first
      await cancelAllNotifications();

      if (!isEnabled) {
        return NotificationStatus(
          isEnabled: false,
          hasPermission: false,
          scheduledCount: 0,
          health: NotificationHealth.unhealthy,
          lastScheduledAt: DateTime.now(),
        );
      }

      int scheduledCount = 0;
      DateTime? nextNotificationTime;

      // Tier 1: Schedule immediate notifications (next 48 hours)
      final tier1Result = await _scheduleImmediateNotifications(
        startHourIndex: startHourIndex,
        endHourIndex: endHourIndex,
      );
      scheduledCount += tier1Result.count;
      nextNotificationTime = tier1Result.nextTime;

      // Tier 2: Schedule daily bootstrap notification
      final tier2Result = await _scheduleDailyBootstrap(startHourIndex);
      if (tier2Result) scheduledCount++;

      // Verify what was actually scheduled
      final pending = await _plugin.pendingNotificationRequests();
      final actualCount = pending.length;

      if (actualCount != scheduledCount) {
        debugPrint('⚠️  Scheduled $scheduledCount but only $actualCount are pending');
      }

      debugPrint('✅ Scheduling complete: $actualCount notifications active');

      return NotificationStatus(
        isEnabled: true,
        hasPermission: true,
        scheduledCount: actualCount,
        nextNotificationTime: nextNotificationTime,
        lastScheduledAt: DateTime.now(),
        health: NotificationHealth.fromScheduledCount(actualCount, null),
      );

    } catch (e) {
      debugPrint('❌ Notification scheduling failed: $e');
      return NotificationStatus(
        isEnabled: isEnabled,
        hasPermission: false,
        scheduledCount: 0,
        lastError: e.toString(),
        lastScheduledAt: DateTime.now(),
        health: NotificationHealth.unhealthy,
      );
    }
  }

  /// Tier 1: Schedule individual notifications for the next 48 hours
  Future<_ScheduleResult> _scheduleImmediateNotifications({
    required int startHourIndex,
    required int endHourIndex,
  }) async {
    debugPrint('📅 Tier 1: Scheduling immediate notifications...');

    final now = tz.TZDateTime.now(tz.local);
    int scheduledCount = 0;
    DateTime? firstNotificationTime;

    // Calculate how many slots we need per day
    final slotsPerDay = endHourIndex - startHourIndex;

    // Schedule notifications for the next 48 hours
    for (int hour = 0; hour < _immediateHoursAhead && scheduledCount < _maxImmediateNotifications; hour++) {
      final targetTime = now.add(Duration(hours: hour));

      // Check if this hour falls within the user's time range
      final hourIndex = targetTime.hour * 2 + (targetTime.minute >= 30 ? 1 : 0);

      if (hourIndex >= startHourIndex && hourIndex < endHourIndex) {
        // Schedule for both :00 and :30 if within range
        for (int halfHour = 0; halfHour < 2 && scheduledCount < _maxImmediateNotifications; halfHour++) {
          final minute = halfHour * 30;
          final timeIndex = targetTime.hour * 2 + halfHour;

          if (timeIndex >= startHourIndex && timeIndex < endHourIndex) {
            var scheduledTime = tz.TZDateTime(
              tz.local,
              targetTime.year,
              targetTime.month,
              targetTime.day,
              targetTime.hour,
              minute,
            );

            // Only schedule if in the future
            if (scheduledTime.isAfter(now)) {
              await _scheduleIndividualNotification(
                id: _generateNotificationId(scheduledCount, timeIndex),
                scheduledTime: scheduledTime,
                timeIndex: timeIndex,
              );

              scheduledCount++;
              firstNotificationTime ??= scheduledTime;

              if (scheduledCount <= 3) {
                debugPrint('   Scheduled #$scheduledCount: ${scheduledTime.toString().substring(0, 19)}');
              }
            }
          }
        }
      }
    }

    debugPrint('   Tier 1 complete: $scheduledCount immediate notifications');

    return _ScheduleResult(
      count: scheduledCount,
      nextTime: firstNotificationTime,
    );
  }

  /// Tier 2: Schedule daily recurring notification for bootstrap
  Future<bool> _scheduleDailyBootstrap(int startHourIndex) async {
    debugPrint('📅 Tier 2: Scheduling daily bootstrap notification...');

    try {
      final now = tz.TZDateTime.now(tz.local);
      final hour = startHourIndex ~/ 2;
      final minute = (startHourIndex % 2) * 30;

      // Schedule for tomorrow at the start time
      var bootstrapTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (bootstrapTime.isBefore(now) || bootstrapTime.isAtSameMomentAs(now)) {
        bootstrapTime = bootstrapTime.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'daily_bootstrap',
        'Daily Notification Bootstrap',
        channelDescription: 'Ensures notifications continue working',
        importance: Importance.low, // Low priority, runs in background
        priority: Priority.low,
        showWhen: false,
        visibility: NotificationVisibility.secret, // Hide from user
        ongoing: false,
        silent: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Schedule with daily recurrence
      await _plugin.zonedSchedule(
        _bootstrapNotificationId,
        null, // No title - hidden notification
        null, // No body - hidden notification
        bootstrapTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Daily recurrence
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('   Daily bootstrap scheduled at ${bootstrapTime.toString().substring(0, 19)} (recurring)');
      return true;

    } catch (e) {
      debugPrint('   Failed to schedule bootstrap: $e');
      return false;
    }
  }

  /// Schedule a single notification
  Future<void> _scheduleIndividualNotification({
    required int id,
    required tz.TZDateTime scheduledTime,
    required int timeIndex,
  }) async {
    final timeString = TimeUtils.formatTimeForDisplay(
      timeIndex,
      TimeFormat.twelveHour,
    );

    const androidDetails = AndroidNotificationDetails(
      'happiness_reminders',
      'Happiness Reminders',
      channelDescription: 'Reminders to track your happiness',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'happiness_reminder',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      id,
      'Time to track your happiness!',
      'How are you feeling right now? ($timeString)',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Generate unique notification ID
  int _generateNotificationId(int sequence, int timeIndex) {
    // Use sequence number * 100 + time index
    // This gives us unique IDs that don't conflict
    return (sequence * 100) + timeIndex;
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    debugPrint('🔕 Cancelling all scheduled notifications...');
    await _plugin.cancelAll();
  }

  /// Get pending notifications for debugging/monitoring
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  /// Handle bootstrap event - schedule today's remaining notifications
  Future<void> handleBootstrapEvent({
    required int startHourIndex,
    required int endHourIndex,
  }) async {
    debugPrint('🔄 Bootstrap event triggered - scheduling today\'s notifications');

    final now = tz.TZDateTime.now(tz.local);
    int scheduledCount = 0;

    // Schedule remaining notifications for today only
    for (int timeIndex = startHourIndex; timeIndex < endHourIndex; timeIndex++) {
      final hour = timeIndex ~/ 2;
      final minute = (timeIndex % 2) * 30;

      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Only schedule if in the future
      if (scheduledTime.isAfter(now)) {
        await _scheduleIndividualNotification(
          id: _generateNotificationId(1000 + scheduledCount, timeIndex), // Use 1000+ for bootstrap
          scheduledTime: scheduledTime,
          timeIndex: timeIndex,
        );
        scheduledCount++;
      }
    }

    debugPrint('   Bootstrap complete: $scheduledCount notifications for today');
  }
}

/// Result from scheduling operation
class _ScheduleResult {
  final int count;
  final DateTime? nextTime;

  _ScheduleResult({
    required this.count,
    this.nextTime,
  });
}