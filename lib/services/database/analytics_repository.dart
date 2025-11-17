import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';

/// Repository for analytics and statistics database operations
class AnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all distinct dates that have at least one tracked timeslot
  Future<List<String>> getTrackedDates() async {
    final db = await _dbHelper.database;

    final results = await db.rawQuery('''
      SELECT DISTINCT date FROM timeslots
      WHERE happiness_score > 0 OR description IS NOT NULL
      ORDER BY date DESC
    ''');

    return results.map((row) => row['date'] as String).toList();
  }

  /// Get average happiness score for a specific date
  /// Returns null if no timeslots are tracked for that date
  Future<double?> getAverageScoreForDate(String date) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT AVG(happiness_score) as avg_score
      FROM timeslots
      WHERE date = ? AND happiness_score > 0
    ''', [date]);

    final avgScore = result.first['avg_score'];
    return avgScore != null ? (avgScore as num).toDouble() : null;
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    final db = await _dbHelper.database;

    final totalSlots = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM timeslots'),
    );

    final trackedSlots = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM timeslots WHERE happiness_score > 0 OR description IS NOT NULL',
      ),
    );

    final avgScore = await db.rawQuery(
      'SELECT AVG(happiness_score) as avg FROM timeslots WHERE happiness_score > 0',
    );

    return {
      'total_timeslots': totalSlots ?? 0,
      'tracked_timeslots': trackedSlots ?? 0,
      'average_happiness': (avgScore.first['avg'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Delete all data (useful for testing or reset)
  Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.delete('timeslots');
  }
}
