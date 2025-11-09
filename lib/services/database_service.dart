import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/timeslot.dart';
import '../models/app_settings.dart';
import '../core/utils/time_utils.dart';

/// Service for database operations
/// Handles all CRUD operations for timeslots and settings
class DatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ==================== Timeslot Operations ====================

  /// Get all timeslots for a specific date
  /// Returns list of 48 timeslots, creating empty ones for missing entries
  Future<List<Timeslot>> getTimeslotsForDate(String date) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'timeslots',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'time_index ASC',
    );

    // Create map of existing timeslots by time_index
    final existingSlots = <int, Timeslot>{};
    for (final map in results) {
      final slot = Timeslot.fromMap(map);
      existingSlots[slot.timeIndex] = slot;
    }

    // Generate all 48 timeslots, filling in missing ones
    final allSlots = <Timeslot>[];
    final now = DateTime.now();

    for (int i = 0; i < 48; i++) {
      if (existingSlots.containsKey(i)) {
        allSlots.add(existingSlots[i]!);
      } else {
        // Create empty timeslot
        allSlots.add(Timeslot(
          date: date,
          timeIndex: i,
          time: TimeUtils.indexToTime(i),
          happinessScore: 0,
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    return allSlots;
  }

  /// Upsert (insert or update) a timeslot
  /// Uses CONFLICT resolution to update existing entries
  Future<void> upsertTimeslot(Timeslot timeslot) async {
    final db = await _dbHelper.database;

    final map = timeslot.toMap();
    // Remove id for upsert operation
    map.remove('id');

    await db.insert(
      'timeslots',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update happiness score for a specific timeslot
  Future<void> updateHappinessScore(String date, int timeIndex, int score) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // Check if timeslot exists
    final existing = await db.query(
      'timeslots',
      where: 'date = ? AND time_index = ?',
      whereArgs: [date, timeIndex],
    );

    if (existing.isEmpty) {
      // Insert new timeslot
      await db.insert('timeslots', {
        'date': date,
        'time_index': timeIndex,
        'time': TimeUtils.indexToTime(timeIndex),
        'happiness_score': score,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
    } else {
      // Update existing timeslot
      await db.update(
        'timeslots',
        {
          'happiness_score': score,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'date = ? AND time_index = ?',
        whereArgs: [date, timeIndex],
      );
    }
  }

  /// Update description for a specific timeslot
  Future<void> updateDescription(String date, int timeIndex, String? description) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    // Check if timeslot exists
    final existing = await db.query(
      'timeslots',
      where: 'date = ? AND time_index = ?',
      whereArgs: [date, timeIndex],
    );

    if (existing.isEmpty) {
      // Insert new timeslot
      await db.insert('timeslots', {
        'date': date,
        'time_index': timeIndex,
        'time': TimeUtils.indexToTime(timeIndex),
        'happiness_score': 0,
        'description': description,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
    } else {
      // Update existing timeslot
      await db.update(
        'timeslots',
        {
          'description': description,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'date = ? AND time_index = ?',
        whereArgs: [date, timeIndex],
      );
    }
  }

  /// Get top N happiest moments (all time)
  /// Returns timeslots with highest happiness scores
  Future<List<Timeslot>> getTopMoments({int limit = 10}) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'timeslots',
      where: 'happiness_score > 0',
      orderBy: 'happiness_score DESC, updated_at DESC',
      limit: limit,
    );

    return results.map((map) => Timeslot.fromMap(map)).toList();
  }

  /// Get bottom N lowest moments (all time)
  /// Returns timeslots with lowest happiness scores (excluding 0)
  Future<List<Timeslot>> getBottomMoments({int limit = 10}) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'timeslots',
      where: 'happiness_score > 0',
      orderBy: 'happiness_score ASC, updated_at DESC',
      limit: limit,
    );

    return results.map((map) => Timeslot.fromMap(map)).toList();
  }

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

  /// Get timeslots within a date range
  Future<List<Timeslot>> getTimeslotsInRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'timeslots',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, time_index ASC',
    );

    return results.map((map) => Timeslot.fromMap(map)).toList();
  }

  // ==================== Settings Operations ====================

  /// Get all settings
  Future<AppSettings> getSettings() async {
    final db = await _dbHelper.database;

    final results = await db.query('settings');

    // Convert list of maps to single map
    final settingsMap = <String, String>{};
    for (final row in results) {
      settingsMap[row['key'] as String] = row['value'] as String;
    }

    return AppSettings.fromMap(settingsMap);
  }

  /// Update a single setting
  Future<void> updateSetting(String key, String value) async {
    final db = await _dbHelper.database;

    await db.update(
      'settings',
      {'value': value},
      where: 'key = ?',
      whereArgs: [key],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update multiple settings at once
  Future<void> updateSettings(Map<String, String> settings) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      for (final entry in settings.entries) {
        await txn.update(
          'settings',
          {'value': entry.value},
          where: 'key = ?',
          whereArgs: [entry.key],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ==================== Utility Operations ====================

  /// Delete all data (useful for testing or reset)
  Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.delete('timeslots');
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
}
