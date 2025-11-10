/// Application-wide constants
class AppConstants {
  // Database
  static const String databaseName = 'happy_tracks.db';
  static const int databaseVersion = 2;

  // Timeslots
  static const int timeSlotsPerDay = 48; // 24 hours * 2 (half-hour intervals)
  static const int minutesPerSlot = 30;

  // Happiness score range
  static const int minHappinessScore = 0;
  static const int maxHappinessScore = 100;

  // Default settings
  static const int defaultNotificationStartHour = 7; // 7 AM
  static const int defaultNotificationEndHour = 22; // 10 PM
  static const String defaultAccentColorHex = '#6366F1'; // Indigo
  static const String defaultThemeMode = 'system';
  static const String defaultTimeFormat = '12'; // 12-hour format

  // Date format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String displayDateFormat = 'MMMM d, yyyy';
  static const String displayTimeFormat = 'h:mm a';
}
