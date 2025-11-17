import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_settings.dart';
import '../core/utils/color_utils.dart';
import '../features/notifications/models/notification_status.dart';
import '../features/notifications/services/background_task_handler.dart';
import 'database_provider.dart';
import 'enhanced_notification_provider.dart';

part 'settings_provider.g.dart';

/// Provider for app settings
/// Manages user preferences including theme, notifications, and colors
@riverpod
class Settings extends _$Settings {
  @override
  Future<AppSettings> build() async {
    // Load settings from database
    final dbService = ref.read(databaseServiceProvider);
    return await dbService.getSettings();
  }

  /// Update theme mode
  Future<void> updateTheme(ThemeMode mode) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSetting('theme_mode', _themeModeToString(mode));

    // Refresh state
    ref.invalidateSelf();
  }

  /// Update accent color
  Future<void> updateAccentColor(Color color) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSetting('accent_color', ColorUtils.toHex(color));

    // Refresh state
    ref.invalidateSelf();
  }

  /// Toggle notifications on/off
  /// Uses optimistic updates for instant UI feedback with enhanced health monitoring
  Future<void> toggleNotifications(bool enabled) async {
    final dbService = ref.read(databaseServiceProvider);
    final notificationService = ref.read(enhancedNotificationServiceProvider);

    // OPTIMISTIC UPDATE: Update UI state immediately
    // Get current state and create updated version
    final currentState = await future;
    state = AsyncValue.data(currentState.copyWith(
      notificationsEnabled: enabled,
    ));

    // Update database in background
    await dbService.updateSetting('notifications_enabled', enabled.toString());

    if (enabled) {
      // Request permissions (this shows dialog, but UI is already updated)
      final hasPermission = await notificationService.requestPermissions();

      if (hasPermission) {
        // Get current settings to know the time range
        final settings = await dbService.getSettings();

        // Schedule with enhanced service - includes health monitoring
        final status = await notificationService.scheduleNotifications(
          startIndex: settings.notificationStartHour,
          endIndex: settings.notificationEndHour,
          enabled: true,
        );

        // Check if scheduling was successful
        if (status.health == NotificationHealth.unhealthy) {
          debugPrint('⚠️  Notification scheduling unhealthy: ${status.lastError}');

          // Attempt recovery
          final recovered = await notificationService.attemptRecovery();
          if (!recovered) {
            // Show user that notifications need attention
            debugPrint('❌ Recovery failed - notifications need manual fix');
          }
        } else {
          debugPrint('✅ Notifications scheduled: ${status.scheduledCount}');
        }

        // Register background task to maintain notifications
        await BackgroundTaskHandler.registerPeriodicTask();

        // Update notification status provider
        ref.invalidate(notificationStatusNotifierProvider);
      } else {
        // Permission denied - revert the optimistic update
        await dbService.updateSetting('notifications_enabled', 'false');
        ref.invalidateSelf();
      }
    } else {
      // Cancel all notifications (quick operation, safe to await)
      await notificationService.cancelAllNotifications();

      // Cancel background task
      await BackgroundTaskHandler.cancelTask();

      ref.invalidate(notificationStatusNotifierProvider);
    }
  }

  /// Update notification time range (now uses time indices 0-47)
  /// Uses optimistic updates for instant UI feedback with enhanced health monitoring
  Future<void> updateNotificationHours(int startIndex, int endIndex) async {
    if (startIndex < 0 || startIndex > 47 || endIndex < 0 || endIndex > 47) {
      throw ArgumentError('Time indices must be between 0 and 47');
    }

    if (startIndex >= endIndex) {
      throw ArgumentError('Start time must be before end time');
    }

    final dbService = ref.read(databaseServiceProvider);
    final notificationService = ref.read(enhancedNotificationServiceProvider);

    // OPTIMISTIC UPDATE: Update UI state immediately
    final currentState = await future;
    state = AsyncValue.data(currentState.copyWith(
      notificationStartHour: startIndex,
      notificationEndHour: endIndex,
    ));

    // Update database
    await dbService.updateSettings({
      'notification_start_hour': startIndex.toString(),
      'notification_end_hour': endIndex.toString(),
    });

    // Reschedule notifications if they're currently enabled
    final settings = await dbService.getSettings();
    if (settings.notificationsEnabled) {
      // Schedule with enhanced service
      final status = await notificationService.scheduleNotifications(
        startIndex: startIndex,
        endIndex: endIndex,
        enabled: true,
      );

      debugPrint('✅ Rescheduled: ${status.scheduledCount} notifications');

      // Check health and log if issues
      if (status.health != NotificationHealth.healthy) {
        debugPrint('⚠️  Health: ${status.health.name}');
        if (status.lastError != null) {
          debugPrint('   Error: ${status.lastError}');
        }
      }

      // Update notification status provider
      ref.invalidate(notificationStatusNotifierProvider);
    }
  }

  /// Update time format preference
  Future<void> updateTimeFormat(TimeFormat format) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSetting(
      'time_format',
      format == TimeFormat.twelveHour ? '12' : '24',
    );

    // Refresh state
    ref.invalidateSelf();
  }

  /// Mark welcome modal as seen
  /// Called after user dismisses the onboarding welcome modal
  Future<void> markWelcomeSeen() async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSetting('has_seen_welcome', 'true');

    // Refresh state
    ref.invalidateSelf();
  }

  /// Helper to convert ThemeMode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
