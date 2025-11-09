# Project Architecture

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── app.dart                            # Root app widget with theme/routing
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # Time constants, slot count (48)
│   │   └── app_theme.dart              # Theme definitions (light/dark)
│   ├── database/
│   │   ├── database_helper.dart        # SQLite initialization and connection
│   │   └── migrations.dart             # Schema version migrations
│   └── utils/
│       ├── date_utils.dart             # Date formatting helpers
│       ├── time_utils.dart             # Timeslot index calculations
│       └── color_utils.dart            # Opacity calculations based on score
│
├── models/
│   ├── timeslot.dart                   # Timeslot data model
│   └── app_settings.dart               # Settings data model
│
├── providers/
│   ├── timeslot_provider.dart          # Riverpod timeslot state management
│   ├── settings_provider.dart          # Riverpod settings state management
│   ├── theme_provider.dart             # Theme state management
│   └── selected_date_provider.dart     # Currently viewing date state
│
├── services/
│   ├── database_service.dart           # CRUD operations for timeslots/settings
│   ├── notification_service.dart       # Local notification scheduling
│   └── backup_service.dart             # Future: export/import functionality
│
├── widgets/
│   ├── common/
│   │   ├── app_scaffold.dart           # Reusable scaffold with nav
│   │   └── loading_indicator.dart      # Consistent loading UI
│   ├── timeslot/
│   │   ├── timeslot_list_item.dart     # Individual timeslot widget
│   │   ├── timeslot_drag_detector.dart # Horizontal drag gesture handler
│   │   └── timeslot_editor_dialog.dart # Modal for text description entry
│   ├── calendar/
│   │   ├── calendar_grid.dart          # Month view grid
│   │   └── calendar_day_cell.dart      # Individual day cell with mini viz
│   ├── heatmap/
│   │   ├── heatmap_grid.dart           # Dot grid visualization
│   │   ├── heatmap_dot.dart            # Individual dot in heatmap
│   │   └── description_carousel.dart   # Top/bottom 10 carousel
│   └── settings/
│       ├── theme_toggle.dart           # Light/Dark theme toggle
│       ├── notification_toggle.dart    # Enable/disable notifications
│       ├── time_range_picker.dart      # Start/end hour pickers
│       └── color_picker.dart           # Accent color picker
│
└── screens/
    ├── home_screen.dart                # Main timeslot list view
    ├── calendar_screen.dart            # Past days calendar view
    ├── analysis_screen.dart            # Heatmap + carousel view
    └── settings_screen.dart            # Settings menu
```

## Screen Breakdown

### 1. Home Screen (Main Timeslot View)

**Purpose:** Primary interface for tracking happiness throughout the day.

**Widget Hierarchy:**
```
HomeScreen
├── AppBar
│   ├── Title: "Today" or formatted selected date
│   ├── IconButton: Navigate to Calendar (calendar icon)
│   ├── IconButton: Navigate to Analysis (chart icon)
│   └── IconButton: Navigate to Settings (cog icon)
│
├── TimeslotList (ListView.builder, 48 items)
│   └── TimeslotListItem (for each half-hour)
│       ├── TimeLabel (Container)
│       │   └── Text: "09:00", "09:30", etc.
│       │
│       ├── HorizontalDragDetector (GestureDetector)
│       │   ├── ColoredContainer (animated opacity based on score)
│       │   └── ScoreBadge (overlay)
│       │       └── Text: "0" to "100"
│       │
│       └── GestureDetector (onTap -> open editor)
│           └── DescriptionPreview
│               └── Text: First line of description or "Add note..."
│
└── FloatingActionButton (optional)
    └── Icon: plus (quick add for current time)
```

**Behavior:**
- Horizontal drag left/right adjusts happiness score
- Real-time visual feedback: score number + opacity change
- Tap opens `TimeslotEditorDialog` for description
- Auto-scrolls to current time index on initial load
- Pull-to-refresh updates current day

---

### 2. Calendar Screen (Historical View)

**Purpose:** Browse and edit past tracked days.

**Widget Hierarchy:**
```
CalendarScreen
├── AppBar
│   ├── Title: "History"
│   ├── MonthYearSelector (dropdown or swipe)
│   └── IconButton: Jump to today
│
├── CalendarGrid (GridView, 7 columns)
│   └── CalendarDayCell (for each day in month)
│       ├── DayNumber (Container)
│       │   └── Text: "1", "2", etc.
│       │
│       ├── MiniHeatmapBar (Custom Paint or Row of tiny dots)
│       │   └── Compressed visualization of 48 timeslots
│       │
│       └── AverageScoreBadge (optional)
│           └── Text: avg happiness if tracked
│
└── BottomSheet (shown on day tap)
    ├── SheetHeader
    │   ├── Title: Formatted date
    │   └── CloseButton
    │
    └── TimeslotList (REUSED from HomeScreen)
        └── Same TimeslotListItem widgets
```

**Behavior:**
- Each cell shows mini preview of that day's tracking
- Empty/untracked days appear grayed out
- Tap opens bottom sheet with full day view
- Can edit any historical timeslot
- Swipe left/right to change months

---

### 3. Analysis Screen (Insights + Heatmap)

**Purpose:** Visualize patterns and review memorable moments.

**Widget Hierarchy:**
```
AnalysisScreen
├── AppBar
│   ├── Title: "Insights"
│   └── DateRangeSelector (week/month/all time)
│
└── ScrollView (SingleChildScrollView)
    │
    ├── HeatmapSection
    │   ├── SectionTitle: "Happiness Patterns"
    │   │
    │   ├── HeatmapGrid (Horizontally scrollable)
    │   │   └── GridView (48 rows × N day columns)
    │   │       └── HeatmapDot (for each timeslot)
    │   │           └── Container (circle with opacity)
    │   │
    │   └── Legend
    │       └── Row: Low (light) → High (saturated)
    │
    ├── MomentsSection
    │   ├── ToggleButtons
    │   │   ├── "Top 10 Moments" (selected by default)
    │   │   └── "Bottom 10 Moments"
    │   │
    │   └── DescriptionCarousel (PageView)
    │       └── CarouselCard (swipeable)
    │           ├── ScoreBadge (large, colored)
    │           ├── DateTime: "Nov 9, 2025 • 3:30 PM"
    │           ├── DescriptionText: What user was doing
    │           └── ColoredBackground (with score opacity)
    │
    └── StatsSection (optional future enhancement)
        ├── AverageDailyHappiness
        ├── BestDay / WorstDay
        └── CompletionRate (% of slots tracked)
```

**Behavior:**
- Heatmap scrolls horizontally for many days
- Each dot is interactive (tap to see details in bottom sheet)
- Carousel auto-advances every 5 seconds
- Toggle switches between top/bottom 10 immediately
- Date range filter updates all visualizations

---

### 4. Settings Screen

**Purpose:** Configure app preferences and notifications.

**Widget Hierarchy:**
```
SettingsScreen
├── AppBar
│   └── Title: "Settings"
│
└── ListView (scrollable settings list)
    │
    ├── AppearanceSection
    │   ├── SectionHeader: "Appearance"
    │   │
    │   ├── ThemeToggle (SegmentedButton)
    │   │   ├── Option: Light
    │   │   ├── Option: Dark
    │   │   └── Option: System
    │   │
    │   └── ColorPicker
    │       ├── Label: "Accent Color"
    │       └── ColorWell (opens color picker dialog)
    │
    ├── NotificationSection
    │   ├── SectionHeader: "Notifications"
    │   │
    │   ├── NotificationToggle (Switch)
    │   │   └── Label: "Enable reminders"
    │   │
    │   └── TimeRangePicker (disabled if toggle off)
    │       ├── StartHourPicker: "Start at 7:00 AM"
    │       └── EndHourPicker: "End at 10:00 PM"
    │
    ├── DataSection (future)
    │   ├── SectionHeader: "Data"
    │   ├── ExportButton: "Export all data"
    │   └── ImportButton: "Import data"
    │
    └── AboutSection
        ├── SectionHeader: "About"
        ├── AppVersion: "v1.0.0"
        └── PrivacyPolicy: Link (future)
```

**Behavior:**
- Theme changes apply immediately
- Accent color picker shows live preview
- Notification toggle reschedules/cancels all notifications
- Time range updates notification schedule
- All settings persist to database

---

## State Management (Riverpod)

### Providers

**TimeslotProvider:**
```dart
// Manages timeslot data for selected date
@riverpod
class TimeslotNotifier extends _$TimeslotNotifier {
  Future<List<Timeslot>> build(String date) async {
    return await ref.read(databaseServiceProvider).getTimeslotsForDate(date);
  }

  Future<void> updateScore(int timeIndex, int score) async { ... }
  Future<void> updateDescription(int timeIndex, String description) async { ... }
}
```

**SettingsProvider:**
```dart
// Manages app settings
@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  Future<AppSettings> build() async {
    return await ref.read(databaseServiceProvider).getSettings();
  }

  Future<void> updateTheme(ThemeMode mode) async { ... }
  Future<void> updateAccentColor(Color color) async { ... }
  Future<void> toggleNotifications(bool enabled) async { ... }
  Future<void> updateNotificationHours(int start, int end) async { ... }
}
```

**SelectedDateProvider:**
```dart
// Manages currently viewing date
@riverpod
class SelectedDate extends _$SelectedDate {
  String build() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  void selectDate(DateTime date) {
    state = DateFormat('yyyy-MM-dd').format(date);
  }
}
```

**ThemeProvider:**
```dart
// Manages theme state (derived from settings)
@riverpod
ThemeData theme(ThemeRef ref) {
  final settings = ref.watch(settingsProvider).value;
  // Build theme based on settings
}
```

---

## Services

### DatabaseService

**Responsibilities:**
- Initialize SQLite database
- Execute migrations
- CRUD operations for timeslots
- CRUD operations for settings
- Query helpers (top 10, date ranges, etc.)

**Key Methods:**
```dart
Future<void> init()
Future<List<Timeslot>> getTimeslotsForDate(String date)
Future<void> upsertTimeslot(Timeslot timeslot)
Future<List<Timeslot>> getTopMoments(int limit)
Future<List<Timeslot>> getBottomMoments(int limit)
Future<AppSettings> getSettings()
Future<void> updateSetting(String key, String value)
```

### NotificationService

**Responsibilities:**
- Schedule half-hourly notifications
- Handle notification taps
- Respect time range settings
- Cancel/reschedule on settings change

**Key Methods:**
```dart
Future<void> init()
Future<void> scheduleAllNotifications(int startHour, int endHour)
Future<void> cancelAllNotifications()
Future<void> handleNotificationTap(String payload)
```

---

## Time Utilities

### Time Index Calculation

**Mapping timeslot index to time string:**
```dart
// 0 → "00:00", 1 → "00:30", 2 → "01:00", ..., 47 → "23:30"
String indexToTime(int index) {
  final hour = (index ~/ 2).toString().padLeft(2, '0');
  final minute = (index % 2 == 0) ? '00' : '30';
  return '$hour:$minute';
}
```

**Current timeslot index:**
```dart
int getCurrentTimeIndex() {
  final now = DateTime.now();
  final minutes = now.hour * 60 + now.minute;
  return minutes ~/ 30;
}
```

### Color Utilities

**Calculate opacity based on score:**
```dart
double scoreToOpacity(int score) {
  // 0-20 → 0.2, 21-40 → 0.4, 41-60 → 0.6, 61-80 → 0.8, 81-100 → 1.0
  if (score == 0) return 0.0;
  return ((score / 20).ceil() * 0.2).clamp(0.2, 1.0);
}
```

**Apply opacity to accent color:**
```dart
Color getTimeslotColor(Color accentColor, int score) {
  final opacity = scoreToOpacity(score);
  return accentColor.withOpacity(opacity);
}
```

---

## Navigation

**Routes:**
- `/` - HomeScreen (default)
- `/calendar` - CalendarScreen
- `/analysis` - AnalysisScreen
- `/settings` - SettingsScreen

**Navigation pattern:**
- Bottom navigation bar (optional) or top app bar icons
- Deep linking support for notification taps (opens specific timeslot)

---

## Dependencies

See [PLAN.md](PLAN.md) for full dependency list.

**Core packages:**
- `flutter_riverpod` - State management
- `sqflite` - SQLite database
- `flutter_local_notifications` - Push notifications
- `intl` - Date formatting
- `table_calendar` - Calendar widget
- `carousel_slider` - Carousel component
