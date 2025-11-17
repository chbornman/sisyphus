import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../models/app_settings.dart';

/// Repository for settings database operations
class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get all settings
  Future<AppSettings> getSettings() async {
    final db = await _dbHelper.database;

    final results = await db.query('settings');

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

  /// Update a single setting (nullable version)
  Future<void> updateSettingNullable(String key, String? value) async {
    final db = await _dbHelper.database;

    if (value == null) {
      await db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
