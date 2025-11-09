# Database Schema

HappyTracks uses SQLite for local data storage. All data is stored on-device and persisted forever.

## Tables

### timeslots

Stores individual timeslot entries for happiness tracking.

```sql
CREATE TABLE timeslots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,                    -- Format: YYYY-MM-DD (e.g., "2025-11-09")
  time_index INTEGER NOT NULL,           -- 0-47 (representing 48 half-hour slots)
  time TEXT NOT NULL,                    -- Format: HH:MM (e.g., "09:00", "09:30")
  happiness_score INTEGER DEFAULT 0,     -- Score from 0-100
  description TEXT,                      -- Optional text: what user was doing
  created_at INTEGER NOT NULL,           -- Unix timestamp (milliseconds)
  updated_at INTEGER NOT NULL,           -- Unix timestamp (milliseconds)
  UNIQUE(date, time_index)               -- Ensures one entry per timeslot per day
);
```

**Indexes:**
```sql
CREATE INDEX idx_timeslots_date ON timeslots(date);
CREATE INDEX idx_timeslots_happiness ON timeslots(happiness_score DESC);
```

**Notes:**
- `time_index` maps to timeslots: 0 = 00:00, 1 = 00:30, 2 = 01:00, ..., 47 = 23:30
- `UNIQUE(date, time_index)` constraint prevents duplicate entries for same timeslot
- Happiness scores are constrained to 0-100 in application logic
- All historical data is retained indefinitely

### settings

Stores user preferences and configuration.

```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

**Pre-populated Settings:**

| Key | Value Type | Example | Description |
|-----|------------|---------|-------------|
| `theme_mode` | String | `"light"`, `"dark"`, `"system"` | Current theme preference |
| `accent_color` | Hex String | `"#FF6B6B"` | User-selected accent color |
| `notifications_enabled` | Boolean String | `"true"`, `"false"` | Master notification toggle |
| `notification_start_hour` | Integer String | `"7"` (7am) | Start hour for notifications (0-23) |
| `notification_end_hour` | Integer String | `"22"` (10pm) | End hour for notifications (0-23) |

**Notes:**
- Settings are stored as key-value pairs for flexibility
- All values stored as TEXT, parsed by application
- Settings persist across app restarts

## Data Models

### Timeslot Model (Dart)

```dart
class Timeslot {
  final int? id;
  final String date;           // YYYY-MM-DD
  final int timeIndex;         // 0-47
  final String time;           // HH:MM
  final int happinessScore;    // 0-100
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Constructor, fromMap, toMap methods
}
```

### AppSettings Model (Dart)

```dart
class AppSettings {
  final ThemeMode themeMode;
  final Color accentColor;
  final bool notificationsEnabled;
  final int notificationStartHour;
  final int notificationEndHour;

  // Constructor, fromMap, toMap methods
}
```

## Database Operations

### Common Queries

**Get all timeslots for a specific date:**
```sql
SELECT * FROM timeslots
WHERE date = ?
ORDER BY time_index ASC;
```

**Get top 10 happiest moments (all time):**
```sql
SELECT * FROM timeslots
WHERE happiness_score > 0
ORDER BY happiness_score DESC, updated_at DESC
LIMIT 10;
```

**Get bottom 10 lowest moments (all time):**
```sql
SELECT * FROM timeslots
WHERE happiness_score > 0
ORDER BY happiness_score ASC, updated_at DESC
LIMIT 10;
```

**Get all dates with any tracked data:**
```sql
SELECT DISTINCT date FROM timeslots
ORDER BY date DESC;
```

**Get average happiness for a specific date:**
```sql
SELECT AVG(happiness_score) as avg_score
FROM timeslots
WHERE date = ? AND happiness_score > 0;
```

**Upsert timeslot entry:**
```sql
INSERT INTO timeslots (date, time_index, time, happiness_score, description, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(date, time_index)
DO UPDATE SET
  happiness_score = excluded.happiness_score,
  description = excluded.description,
  updated_at = excluded.updated_at;
```

## Migration Strategy

### Version 1 (Initial)
- Create `timeslots` table
- Create `settings` table
- Create indexes
- Insert default settings

### Future Migrations
Future schema changes will be versioned and applied incrementally using SQLite's `PRAGMA user_version`.

Example future additions might include:
- `tags` table for categorizing activities
- `goals` table for tracking happiness targets
- `notes` table for daily reflections
