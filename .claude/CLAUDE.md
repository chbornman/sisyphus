# HappyTracks Project Guidelines

## Project Overview

HappyTracks is a Flutter happiness tracking app that helps users monitor their emotional well-being throughout the day using 48 half-hour timeslots (00:00 - 23:30).

**Tech Stack:**
- Flutter (Material 3)
- Riverpod with code generation (state management)
- SQLite (local database)
- flutter_local_notifications (push notifications)

**Key Principle:** Simple, clean, modern design with thin bezels and 8px rounded corners. No emojis unless explicitly requested.

## Architecture Patterns

### State Management
- **Always use Riverpod with code generation** - not manual providers
- Use `@riverpod` annotation and `build_runner` to generate providers
- Provider files should have `.g.dart` part files

```dart
// Good ✓
@riverpod
class Timeslots extends _$Timeslots {
  @override
  Future<List<Timeslot>> build() async { ... }
}

// Bad ✗ - Manual provider
final timeslotsProvider = FutureProvider<List<Timeslot>>((ref) { ... });
```

### Database
- All data stored locally in SQLite
- Keep all historical data forever (it's text-based, minimal storage)
- Use **optimistic updates** to prevent UI flashing
- Update UI state immediately, then persist to database

```dart
// Good ✓ - Optimistic update
state = AsyncValue.data(updatedData);
await dbService.save(data);

// Bad ✗ - Causes flash
await dbService.save(data);
ref.invalidateSelf();
```

### Gestures
- **Relative drag, not absolute positioning**
- Track starting position and calculate delta
- Always provide visual feedback during drag

### Animations
- Use AnimatedSwitcher with KeyedSubtree for page transitions
- One ScrollController per date to avoid conflicts
- 300ms duration with Curves.easeOutCubic

## Code Style & Conventions

### File Organization
```
lib/
├── core/         # Constants, utils, database setup
├── models/       # Data models (Timeslot, AppSettings)
├── providers/    # Riverpod providers with .g.dart
├── services/     # Business logic (DatabaseService, NotificationService)
├── widgets/      # Reusable UI components
└── screens/      # Top-level views
```

### Widget Structure
- Break complex widgets into smaller, focused components
- Put widget-specific helpers in private methods (`_buildSomething`)
- Always add documentation comments explaining WHY, not just WHAT

### Naming
- Providers: `timeslotsProvider`, `settingsProvider`
- Services: `DatabaseService`, `NotificationService`
- Models: `Timeslot`, `AppSettings`
- Widgets: `TimeslotListItem`, `TimeslotEditorDialog`

## Theme & Design

### Colors
- **Light theme:** Background `#FAFAFA`, Surface `#FFFFFF`, Text `#1A1A1A`
- **Dark theme:** Background `#1A1A1A`, Surface `#2A2A2A`, Text `#FAFAFA`
- **Accent color:** User-customizable, applied with opacity based on happiness score
- **Opacity mapping:** Linear 0-100 → 0.0-1.0 (minimum 0.2 for visibility)

### Spacing & Sizing
- Base unit: 8px
- Border radius: 8px (tightly rounded)
- Timeslot height: 56px
- Use `AppTheme.spacing2`, `AppTheme.spacing4`, etc.

### Icons
- Use Material Icons or Heroicons
- **No emojis** unless user explicitly requests

## Critical Implementation Details

### Time Management
- 48 timeslots per day (30-minute intervals)
- Time index: 0-47 (0 = 00:00, 47 = 23:30)
- Use `TimeUtils.indexToTime()` and `timeToIndex()` for conversions
- Date format: `yyyy-MM-dd` (database), `MMMM d, yyyy` (display)

### Future Date Handling
- **Never allow navigation to future dates**
- Grey out future timeslots on today (opacity 0.3)
- Disable drag/tap gestures on future slots
- Hide forward navigation button when viewing today

### Happiness Scoring
- Range: 0-100
- Visual: Opacity changes linearly with each point
- Interaction: Relative horizontal drag (not absolute position)
- Display: Show numeric score badge when > 0

### Data Persistence
- SQLite with migrations system
- Indexes on `date` and `happiness_score` columns
- UNIQUE constraint on (date, time_index)
- Use UPSERT pattern for updates

## Common Tasks

### Adding a New Provider
1. Create file in `lib/providers/`
2. Add `@riverpod` annotation
3. Include `part 'filename.g.dart';`
4. Run `dart run build_runner build --delete-conflicting-outputs`

### Adding a New Screen
1. Create file in `lib/screens/`
2. Use `ConsumerStatefulWidget` if state is needed
3. Add route to navigation (currently placeholder)
4. Follow HomeScreen pattern for structure

### Database Changes
1. Update schema in `lib/core/database/migrations.dart`
2. Increment `databaseVersion` in `app_constants.dart`
3. Add migration logic in `DatabaseMigrations.migrate()`
4. Update corresponding models and services

### Testing Locally
- Run on iOS simulator: `flutter run -d iphone`
- Hot reload: Press `r` in terminal
- Hot restart: Press `R` in terminal
- Check for errors: `flutter analyze`

## Known Gotchas & Solutions

### ❌ ScrollController Conflicts
**Problem:** AnimatedSwitcher creates two scroll views during transition
**Solution:** Use Map of ScrollControllers, one per date

### ❌ UI Flashing on Update
**Problem:** Invalidating provider causes full rebuild
**Solution:** Optimistic updates - update UI state first, then database

### ❌ Drag Jumping to Position
**Problem:** Using absolute position instead of delta
**Solution:** Track dragStartScore and dragStartX, calculate delta

### ❌ Deprecated Riverpod Types
**Info:** `DatabaseServiceRef` warnings are non-breaking, can ignore
**Fix:** Use generic `Ref` type if you want to eliminate warnings

## Phase Implementation Status

✅ **Phase 1:** Foundation (database, models, providers, theme)
✅ **Phase 2:** Core Feature (timeslot tracking with drag gestures)
🚫 **Phase 3:** Calendar (skipped - on back burner)
⏳ **Phase 4:** Analysis (heatmap and top/bottom moments)
⏳ **Phase 5:** Notifications (half-hourly reminders)
✅ **Phase 6:** Settings (theme, colors, notification config, time format)

## Future Enhancements (TODO.md)

See `TODO.md` for full list. Key items:
- Tutorial/onboarding flow
- Push notification interactivity (add score/description without opening app)
- Data export/import
- Advanced analytics and patterns
- Tags/categories for activities

## Testing Guidelines

### Manual Testing Checklist
- [ ] Drag gesture feels natural and responsive
- [ ] No UI flashing when saving data
- [ ] Future timeslots properly disabled
- [ ] Animations smooth (no jank)
- [ ] Data persists across app restarts
- [ ] Scroll position maintained during navigation

### Before Committing
1. Run `flutter analyze` - must have 0 errors
2. Test on iOS simulator
3. Verify hot reload works
4. Check that data persists

## Git Commit Messages

Follow this format:
```
[Phase/Feature]: Brief description

- Bullet point details
- Implementation notes
- Technical decisions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Documentation Files

- **PLAN.md** - High-level feature overview and implementation phases
- **ARCHITECTURE.md** - Detailed widget hierarchies and structure
- **DATABASE.md** - SQLite schema and query patterns
- **TODO.md** - Future enhancements and investigation items
- **CLAUDE.md** - This file - project-specific AI instructions

## When Working on This Project

1. **Read the plan first** - Check PLAN.md and ARCHITECTURE.md before implementing
2. **Follow the phases** - Don't skip ahead, build incrementally
3. **Test frequently** - Hot reload after every significant change
4. **Keep it simple** - Avoid over-engineering, favor clarity
5. **Document decisions** - Add comments explaining WHY, not WHAT
6. **Commit often** - One commit per completed feature/phase

## Important Reminders

- 🚫 **No emojis** in the app unless explicitly requested
- 🚫 **No future dates** - users can only track today and past
- ⚡ **Optimistic updates** - instant UI feedback is critical
- 🎨 **8px everything** - border radius, spacing base unit
- 📱 **Relative gestures** - always track deltas, not absolute positions
- 💾 **Keep all data** - never auto-delete historical tracking

---

**Remember:** This is a personal happiness tracking app. The UX should feel smooth, responsive, and delightful. Every interaction should reinforce the user's commitment to tracking their emotional well-being.
