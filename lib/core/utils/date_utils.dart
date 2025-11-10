import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Utility functions for date formatting and manipulation
class AppDateUtils {
  /// Format date to database format (yyyy-MM-dd)
  static String toDbFormat(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format date for display (e.g., "November 9" or "November 9, 2024" if not current year)
  /// Only shows year when it differs from current year
  static String toDisplayFormat(DateTime date) {
    final now = DateTime.now();
    final isCurrentYear = date.year == now.year;

    // Show year only if not current year
    final format = isCurrentYear ? 'MMMM d' : 'MMMM d, y';
    return DateFormat(format).format(date);
  }

  /// Format date to short format (e.g., "Nov 9")
  static String toShortFormat(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Get today's date in database format
  static String today() {
    return toDbFormat(DateTime.now());
  }

  /// Get yesterday's date in database format
  static String yesterday() {
    return toDbFormat(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Parse database format string to DateTime
  static DateTime fromDbFormat(String dateStr) {
    return DateFormat(AppConstants.dateFormat).parse(dateStr);
  }

  /// Check if a date is today
  static bool isToday(String dateStr) {
    return dateStr == today();
  }

  /// Check if a date is in the past
  static bool isPast(String dateStr) {
    final date = fromDbFormat(dateStr);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    return date.isBefore(todayDate);
  }

  /// Get start and end of week for a given date
  static ({DateTime start, DateTime end}) getWeekRange(DateTime date) {
    final weekday = date.weekday;
    final start = date.subtract(Duration(days: weekday - 1));
    final end = start.add(const Duration(days: 6));
    return (start: start, end: end);
  }

  /// Get start and end of month for a given date
  static ({DateTime start, DateTime end}) getMonthRange(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    return (start: start, end: end);
  }

  /// Get list of dates between two dates (inclusive)
  static List<String> getDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(toDbFormat(current));
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }
}
