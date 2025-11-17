import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../models/timeslot.dart';
import '../../core/utils/time_utils.dart';

/// Repository for timeslot database operations
class TimeslotRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
  Future<void> upsertTimeslot(Timeslot timeslot) async {
    final db = await _dbHelper.database;

    final map = timeslot.toMap();
    map.remove('id');

    await db.insert(
      'timeslots',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update happiness score for a specific timeslot
  Future<void> updateHappinessScore(
    String date,
    int timeIndex,
    int score,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await db.query(
      'timeslots',
      where: 'date = ? AND time_index = ?',
      whereArgs: [date, timeIndex],
    );

    if (existing.isEmpty) {
      await db.insert('timeslots', {
        'date': date,
        'time_index': timeIndex,
        'time': TimeUtils.indexToTime(timeIndex),
        'happiness_score': score,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
    } else {
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
  Future<void> updateDescription(
    String date,
    int timeIndex,
    String? description,
  ) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final existing = await db.query(
      'timeslots',
      where: 'date = ? AND time_index = ?',
      whereArgs: [date, timeIndex],
    );

    if (existing.isEmpty) {
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

  /// Get timeslots within a date range
  Future<List<Timeslot>> getTimeslotsInRange(
    String startDate,
    String endDate,
  ) async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'timeslots',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC, time_index ASC',
    );

    return results.map((map) => Timeslot.fromMap(map)).toList();
  }
}
