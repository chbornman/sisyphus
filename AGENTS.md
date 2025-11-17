# Flutter Sisyphus Project - Agent Guidelines

## Build & Test Commands
```bash
flutter analyze              # Run static analysis
flutter test                # Run all tests
flutter test path/to/test.dart  # Run single test file
flutter build ios --release    # Build iOS release
flutter build apk --release    # Build Android release
dart run build_runner build  # Generate Riverpod providers
```

## Code Style & Conventions
- **State Management**: Use Riverpod with code generation (`@riverpod` annotations) - never manual providers
- **Imports**: Relative imports for project files (`../models/timeslot.dart`), package imports for Flutter/packages
- **Provider Files**: Must have `.g.dart` part files and run `dart run build_runner build` after changes
- **Database Updates**: Use optimistic updates (update UI state first, then persist) to prevent flashing
- **UI Design**: Material 3, thin bezels, 8px rounded corners, NO emojis unless explicitly requested
- **Comments**: Use triple-slash `///` for documentation, explain WHY not just WHAT
- **Async/Await**: Always use async/await instead of .then() chains
- **Error Handling**: Use try-catch blocks for database/notification operations
- **Naming**: snake_case for files, PascalCase for classes, camelCase for variables/methods
- **Testing**: Create test files in `test/` mirroring `lib/` structure