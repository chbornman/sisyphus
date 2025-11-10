import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_settings.dart';
import '../core/utils/color_utils.dart';
import 'database_provider.dart';

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
  Future<void> toggleNotifications(bool enabled) async {
    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSetting('notifications_enabled', enabled.toString());

    // TODO: Update notification scheduling
    // This will be implemented when we add NotificationService

    // Refresh state
    ref.invalidateSelf();
  }

  /// Update notification time range
  Future<void> updateNotificationHours(int startHour, int endHour) async {
    if (startHour < 0 || startHour > 23 || endHour < 0 || endHour > 23) {
      throw ArgumentError('Hours must be between 0 and 23');
    }

    if (startHour >= endHour) {
      throw ArgumentError('Start hour must be before end hour');
    }

    final dbService = ref.read(databaseServiceProvider);
    await dbService.updateSettings({
      'notification_start_hour': startHour.toString(),
      'notification_end_hour': endHour.toString(),
    });

    // TODO: Reschedule notifications
    // This will be implemented when we add NotificationService

    // Refresh state
    ref.invalidateSelf();
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
