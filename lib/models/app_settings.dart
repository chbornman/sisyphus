import 'package:flutter/material.dart';
import 'package:happy_tracks/core/utils/color_utils.dart';

/// Application settings model
/// Stores user preferences for theme, notifications, and customization
class AppSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final bool notificationsEnabled;
  final int notificationStartHour; // 0-23
  final int notificationEndHour; // 0-23

  const AppSettings({
    required this.themeMode,
    required this.accentColor,
    required this.notificationsEnabled,
    required this.notificationStartHour,
    required this.notificationEndHour,
  });

  /// Create settings from database map
  /// Map contains settings as key-value pairs
  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      themeMode: _parseThemeMode(map['theme_mode'] ?? 'system'),
      accentColor: ColorUtils.fromHex(map['accent_color'] ?? '#6366F1'),
      notificationsEnabled: map['notifications_enabled'] == 'true',
      notificationStartHour: int.tryParse(map['notification_start_hour'] ?? '7') ?? 7,
      notificationEndHour: int.tryParse(map['notification_end_hour'] ?? '22') ?? 22,
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

  /// Create a copy with updated fields
  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? accentColor,
    bool? notificationsEnabled,
    int? notificationStartHour,
    int? notificationEndHour,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationStartHour: notificationStartHour ?? this.notificationStartHour,
      notificationEndHour: notificationEndHour ?? this.notificationEndHour,
    );
  }

  /// Validate notification hours
  bool get hasValidNotificationHours =>
      notificationStartHour >= 0 &&
      notificationStartHour <= 23 &&
      notificationEndHour >= 0 &&
      notificationEndHour <= 23 &&
      notificationStartHour < notificationEndHour;

  /// Get number of notification hours per day
  int get notificationHoursPerDay => notificationEndHour - notificationStartHour;

  @override
  String toString() {
    return 'AppSettings(theme: $themeMode, notifications: $notificationsEnabled, '
        'hours: $notificationStartHour-$notificationEndHour)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AppSettings &&
        other.themeMode == themeMode &&
        other.accentColor == accentColor &&
        other.notificationsEnabled == notificationsEnabled &&
        other.notificationStartHour == notificationStartHour &&
        other.notificationEndHour == notificationEndHour;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      accentColor,
      notificationsEnabled,
      notificationStartHour,
      notificationEndHour,
    );
  }
}
