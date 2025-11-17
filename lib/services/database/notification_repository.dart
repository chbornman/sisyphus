import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';

/// Repository for notification status database operations
class NotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get notification status from settings
  Future<Map<String, String>> getNotificationStatus() async {
    final db = await _dbHelper.database;

    final results = await db.query(
      'settings',
      where: 'key IN (?, ?, ?, ?, ?, ?)',
      whereArgs: [
        'scheduled_count',
        'next_notification_time',
        'last_scheduled_at',
        'last_bootstrap_at',
        'last_error',
        'has_permission',
      ],
    );

    final statusMap = <String, String>{};
    for (final row in results) {
      statusMap[row['key'] as String] = row['value'] as String;
    }

    return statusMap;
  }

  /// Save notification status to settings
  Future<void> saveNotificationStatus(Map<String, String> status) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      for (final entry in status.entries) {
        await txn.insert(
          'settings',
          {
            'key': entry.key,
            'value': entry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
