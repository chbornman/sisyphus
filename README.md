# Sisyphus - Happiness Tracker

Track your happiness throughout the day, every half hour. Build awareness of your emotional well-being and discover what truly makes you happy.

## Features

- **Simple Tracking**: 48 half-hour timeslots per day (00:00 - 23:30)
- **Intuitive Gestures**: Drag horizontally to set happiness score (0-100)
- **Pattern Discovery**: Heatmap visualization shows your happiness patterns over time
- **Memorable Moments**: Carousel of your highest and lowest moments
- **Customizable Notifications**: Half-hourly reminders on your schedule
- **Privacy First**: All data stored locally on your device
- **Dark Mode**: Full dark mode support

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management with code generation
- **SQLite** - Local database for happiness data
- **Material 3** - Modern design system

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- iOS development tools (Xcode) or Android Studio
- CocoaPods (for iOS)

### Installation

```bash
# Get dependencies
flutter pub get

# Generate Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### iOS Development

```bash
# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Build for iOS
flutter build ios --release
```

### Fastlane Automation

Automated build and deployment for iOS:

```bash
cd ios

# Build locally
fastlane build

# Upload to TestFlight
fastlane beta

# Upload to App Store Connect
fastlane release

# Update App Store metadata
fastlane deliver
```

## Architecture

- **State Management**: Riverpod with code generation (`@riverpod` annotation)
- **Database**: SQLite with migration system
- **Navigation**: Date-based with swipe gestures
- **Animations**: AnimatedSwitcher with 300ms transitions
- **Theme**: Dynamic colors with user-customizable accent

## Privacy

Sisyphus is privacy-first:

- No account or login required
- All data stored locally on device
- No analytics or tracking
- No internet connection needed

See [PRIVACY.md](PRIVACY.md) for full privacy policy.

## License

Copyright © 2025 Caleb Bornman

## Contact

- GitHub: [@chbornman](https://github.com/chbornman)
- Email: calebbornman@gmail.com
