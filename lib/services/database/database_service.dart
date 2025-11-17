import '../../models/timeslot.dart';
import '../../models/app_settings.dart';
import 'timeslot_repository.dart';
import 'settings_repository.dart';
import 'notification_repository.dart';
import 'analytics_repository.dart';

/// Facade service for database operations
/// Delegates to specialized repositories for backwards compatibility
class DatabaseService {
  final TimeslotRepository _timeslotRepo = TimeslotRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();

  // ==================== Timeslot Operations ====================

  Future<List<Timeslot>> getTimeslotsForDate(String date) async {
    return _timeslotRepo.getTimeslotsForDate(date);
  }

  Future<void> upsertTimeslot(Timeslot timeslot) async {
    return _timeslotRepo.upsertTimeslot(timeslot);
  }

  Future<void> updateHappinessScore(
    String date,
    int timeIndex,
    int score,
  ) async {
    return _timeslotRepo.updateHappinessScore(date, timeIndex, score);
  }

  Future<void> updateDescription(
    String date,
    int timeIndex,
    String? description,
  ) async {
    return _timeslotRepo.updateDescription(date, timeIndex, description);
  }

  Future<List<Timeslot>> getTopMoments({int limit = 10}) async {
    return _timeslotRepo.getTopMoments(limit: limit);
  }

  Future<List<Timeslot>> getBottomMoments({int limit = 10}) async {
    return _timeslotRepo.getBottomMoments(limit: limit);
  }

  Future<List<Timeslot>> getTimeslotsInRange(
    String startDate,
    String endDate,
  ) async {
    return _timeslotRepo.getTimeslotsInRange(startDate, endDate);
  }

  // ==================== Settings Operations ====================

  Future<AppSettings> getSettings() async {
    return _settingsRepo.getSettings();
  }

  Future<void> updateSetting(String key, String value) async {
    return _settingsRepo.updateSetting(key, value);
  }

  Future<void> updateSettings(Map<String, String> settings) async {
    return _settingsRepo.updateSettings(settings);
  }

  Future<void> updateSettingNullable(String key, String? value) async {
    return _settingsRepo.updateSettingNullable(key, value);
  }

  // ==================== Notification Status Operations ====================

  Future<Map<String, String>> getNotificationStatus() async {
    return _notificationRepo.getNotificationStatus();
  }

  Future<void> saveNotificationStatus(Map<String, String> status) async {
    return _notificationRepo.saveNotificationStatus(status);
  }

  // ==================== Analytics Operations ====================

  Future<List<String>> getTrackedDates() async {
    return _analyticsRepo.getTrackedDates();
  }

  Future<double?> getAverageScoreForDate(String date) async {
    return _analyticsRepo.getAverageScoreForDate(date);
  }

  Future<Map<String, dynamic>> getStats() async {
    return _analyticsRepo.getStats();
  }

  Future<void> clearAllData() async {
    return _analyticsRepo.clearAllData();
  }
}
