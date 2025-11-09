import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/utils/date_utils.dart';

part 'selected_date_provider.g.dart';

/// Provider for currently selected date
/// Defaults to today's date
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  String build() {
    // Initialize with today's date
    return AppDateUtils.today();
  }

  /// Select a specific date
  void selectDate(DateTime date) {
    state = AppDateUtils.toDbFormat(date);
  }

  /// Select today
  void selectToday() {
    state = AppDateUtils.today();
  }

  /// Select yesterday
  void selectYesterday() {
    state = AppDateUtils.yesterday();
  }

  /// Navigate to previous day
  void previousDay() {
    final current = AppDateUtils.fromDbFormat(state);
    final previous = current.subtract(const Duration(days: 1));
    state = AppDateUtils.toDbFormat(previous);
  }

  /// Navigate to next day
  void nextDay() {
    final current = AppDateUtils.fromDbFormat(state);
    final next = current.add(const Duration(days: 1));
    state = AppDateUtils.toDbFormat(next);
  }
}
