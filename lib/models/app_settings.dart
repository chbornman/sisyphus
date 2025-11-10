import 'package:flutter/material.dart';
import 'package:happy_tracks/core/constants/app_constants.dart';
import 'package:happy_tracks/core/utils/color_utils.dart';

/// Time format preference
enum TimeFormat {
  twelveHour,
  twentyFourHour,
}

/// Application settings model
/// Stores user preferences for theme, notifications, and customization
class AppSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final bool notificationsEnabled;
  final int notificationStartHour; // 0-47 (time index, 30-min slots)
  final int notificationEndHour; // 0-47 (time index, 30-min slots)
  final TimeFormat timeFormat;

  const AppSettings({
    required this.themeMode,
    required this.accentColor,
    required this.notificationsEnabled,
    required this.notificationStartHour,
    required this.notificationEndHour,
    required this.timeFormat,
  });

  /// Create settings from database map
  /// Map contains settings as key-value pairs
  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      themeMode: _parseThemeMode(map['theme_mode'] ?? 'system'),
      accentColor: ColorUtils.fromHex(map['accent_color'] ?? '#6366F1'),
      notificationsEnabled: map['notifications_enabled'] == 'true',
      notificationStartHour: int.tryParse(map['notification_start_hour'] ?? AppConstants.defaultNotificationStartHour.toString()) ?? AppConstants.defaultNotificationStartHour, // 7:00 AM
      notificationEndHour: int.tryParse(map['notification_end_hour'] ?? AppConstants.defaultNotificationEndHour.toString()) ?? AppConstants.defaultNotificationEndHour, // 10:00 PM
      timeFormat: _parseTimeFormat(map['time_format'] ?? '12'),
    );
  }

  /// Convert settings to database map
  Map<String, String> toMap() {
    return {
      'theme_mode': _themeModeToString(themeMode),
      'accent_color': ColorUtils.toHex(accentColor),
      'notifications_enabled': notificationsEnabled.toString(),
      'notification_start_hour': notificationStartHour.toString(),
      'notification_end_hour': notificationEndHour.toString(),
      'time_format': _timeFormatToString(timeFormat),
    };
  }

  /// Parse ThemeMode from string
  static ThemeMode _parseThemeMode(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode to string
  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Parse TimeFormat from string
  static TimeFormat _parseTimeFormat(String value) {
    switch (value) {
      case '12':
        return TimeFormat.twelveHour;
      case '24':
        return TimeFormat.twentyFourHour;
      default:
        return TimeFormat.twelveHour; // Default to 12-hour
    }
  }

  /// Convert TimeFormat to string
  static String _timeFormatToString(TimeFormat format) {
    switch (format) {
      case TimeFormat.twelveHour:
        return '12';
      case TimeFormat.twentyFourHour:
        return '24';
    }
  }

  /// Create a copy with updated fields
  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? notificationsEnabled,
    int? notificationStartHour,
    int? notificationEndHour,
    TimeFormat? timeFormat,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationStartHour: notificationStartHour ?? this.notificationStartHour,
      notificationEndHour: notificationEndHour ?? this.notificationEndHour,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }

  /// Validate notification hours
  bool get hasValidNotificationHours =>
      notificationStartHour >= 0 &&
      notificationStartHour <= 47 &&
      notificationEndHour >= 0 &&
      notificationEndHour <= 47 &&
      notificationStartHour < notificationEndHour;

  /// Get number of notification slots per day (30-min increments)
  int get notificationSlotsPerDay => notificationEndHour - notificationStartHour;

  @override
  String toString() {
    return 'AppSettings(theme: $themeMode, notifications: $notificationsEnabled, '
        'hours: $notificationStartHour-$notificationEndHour, timeFormat: $timeFormat)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.accentColor == accentColor &&
        other.notificationsEnabled == notificationsEnabled &&
        other.notificationStartHour == notificationStartHour &&
        other.notificationEndHour == notificationEndHour &&
        other.timeFormat == timeFormat;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      accentColor,
      notificationsEnabled,
      notificationStartHour,
      notificationEndHour,
      timeFormat,
    );
  }
}
