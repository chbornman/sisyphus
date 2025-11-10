import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_settings.dart';
import '../core/utils/color_utils.dart';
import 'database_provider.dart';
import 'notification_provider.dart';

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
  /// Uses optimistic updates for instant UI feedback
  Future<void> toggleNotifications(bool enabled) async {
    final dbService = ref.read(databaseServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);

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
        // Schedule notifications in background (don't await)
        // Get current settings to know the time range
        final settings = await dbService.getSettings();

        // Fire and forget - schedule notifications without blocking
        // This prevents UI from freezing while scheduling 100+ notifications
        notificationService.scheduleNotifications(
          startIndex: settings.notificationStartHour,
          endIndex: settings.notificationEndHour,
        ).catchError((error) {
          // Log error but don't crash the app
          // The notifications will be rescheduled next time the app starts
          debugPrint('Error scheduling notifications: $error');
        });
      } else {
        // Permission denied - revert the optimistic update
        await dbService.updateSetting('notifications_enabled', 'false');
        ref.invalidateSelf();
      }
    } else {
      // Cancel all notifications (quick operation, safe to await)
      await notificationService.cancelAllNotifications();
    }
  }

  /// Update notification time range (now uses time indices 0-47)
  /// Uses optimistic updates for instant UI feedback
  Future<void> updateNotificationHours(int startIndex, int endIndex) async {
    if (startIndex < 0 || startIndex > 47 || endIndex < 0 || endIndex > 47) {
      throw ArgumentError('Time indices must be between 0 and 47');
    }

    if (startIndex >= endIndex) {
      throw ArgumentError('Start time must be before end time');
    }

    final dbService = ref.read(databaseServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);

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
      // Fire and forget - reschedule without blocking UI
      notificationService.rescheduleNotifications(
        startIndex: startIndex,
        endIndex: endIndex,
      ).catchError((error) {
        debugPrint('Error rescheduling notifications: $error');
      });
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
