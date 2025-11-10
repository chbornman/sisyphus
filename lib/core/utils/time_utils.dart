import '../../models/app_settings.dart';
import '../constants/app_constants.dart';

/// Utility functions for timeslot calculations
class TimeUtils {
  /// Convert timeslot index (0-47) to time string (HH:mm)
  /// Example: 0 -> "00:00", 1 -> "00:30", 2 -> "01:00", 47 -> "23:30"
  static String indexToTime(int index) {
    if (index < 0 || index >= AppConstants.timeSlotsPerDay) {
      throw ArgumentError('Invalid time index: $index');
    }

    final hour = (index ~/ 2).toString().padLeft(2, '0');
    final minute = (index % 2 == 0) ? '00' : '30';
    return '$hour:$minute';
  }

  /// Convert time string (HH:mm) to timeslot index (0-47)
  /// Example: "00:00" -> 0, "00:30" -> 1, "23:30" -> 47
  static int timeToIndex(String time) {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid time format: $time');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    if (hour < 0 || hour > 23 || (minute != 0 && minute != 30)) {
      throw ArgumentError('Invalid time value: $time');
    }

    return hour * 2 + (minute == 30 ? 1 : 0);
  }

  /// Get current timeslot index based on current time
  /// Rounds down to nearest half hour
  static int getCurrentTimeIndex() {
    final now = DateTime.now();
    final totalMinutes = now.hour * 60 + now.minute;
    return totalMinutes ~/ AppConstants.minutesPerSlot;
  }

  /// Get DateTime for a specific date and time index
  static DateTime getDateTimeForSlot(String date, int timeIndex) {
    final dateTime = DateTime.parse(date);
    final hour = timeIndex ~/ 2;
    final minute = (timeIndex % 2) * 30;
    return DateTime(dateTime.year, dateTime.month, dateTime.day, hour, minute);
  }

  /// Generate all timeslot time strings for a day
  /// Returns list of 48 time strings: ["00:00", "00:30", ..., "23:30"]
  static List<String> generateAllTimeslots() {
    return List.generate(
      AppConstants.timeSlotsPerDay,
      (index) => indexToTime(index),
    );
  }

  /// Format time index based on user's time format preference
  /// Returns formatted time string with or without AM/PM
  /// Example (12-hour): 0 -> "12:00 AM", 13 -> "1:00 PM"
  /// Example (24-hour): 0 -> "00:00", 13 -> "13:00"
  static String formatTimeForDisplay(int index, TimeFormat format) {
    if (index < 0 || index >= AppConstants.timeSlotsPerDay) {
      throw ArgumentError('Invalid time index: $index');
    }

    final hour24 = index ~/ 2;
    final minute = (index % 2 == 0) ? '00' : '30';

    if (format == TimeFormat.twelveHour) {
      // Convert to 12-hour format with AM/PM
      final period = hour24 < 12 ? 'AM' : 'PM';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      return '$hour12:$minute $period';
    } else {
      // 24-hour format
      final hourStr = hour24.toString().padLeft(2, '0');
      return '$hourStr:$minute';
    }
  }
}
