import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';

/// Database migration manager
/// Handles schema versioning and upgrades
class DatabaseMigrations {
  /// Execute migrations based on old and new version
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    // Run migrations sequentially
    if (oldVersion < 1) {
      await _createV1Schema(db);
    }

    // Migrate from V1 to V2 (add time_format setting)
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  /// Create version 1 schema
  /// Initial database structure with timeslots and settings tables
  static Future<void> _createV1Schema(Database db) async {
    // Create timeslots table
    // Stores happiness tracking data for each half-hour timeslot
    await db.execute('''
      CREATE TABLE timeslots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        time_index INTEGER NOT NULL,
        time TEXT NOT NULL,
        happiness_score INTEGER DEFAULT 0,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(date, time_index)
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_timeslots_date ON timeslots(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_timeslots_happiness ON timeslots(happiness_score DESC)
    ''');

    // Create settings table
    // Key-value store for user preferences
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'key': 'theme_mode',
      'value': AppConstants.defaultThemeMode,
    });

    await db.insert('settings', {
      'key': 'accent_color',
      'value': AppConstants.defaultAccentColorHex,
    });

    await db.insert('settings', {
      'key': 'notifications_enabled',
      'value': 'true',
    });

    await db.insert('settings', {
      'key': 'notification_start_hour',
      'value': AppConstants.defaultNotificationStartHour.toString(),
    });

    await db.insert('settings', {
      'key': 'notification_end_hour',
      'value': AppConstants.defaultNotificationEndHour.toString(),
    });

    await db.insert('settings', {
      'key': 'time_format',
      'value': AppConstants.defaultTimeFormat,
    });
  }

  /// Migrate from V1 to V2
  /// Adds time_format setting for users upgrading from V1
  static Future<void> _migrateToV2(Database db) async {
    // Add time_format setting if it doesn't exist
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['time_format'],
    );

    if (result.isEmpty) {
      await db.insert('settings', {
        'key': 'time_format',
        'value': AppConstants.defaultTimeFormat,
      });
    }
  }
}
