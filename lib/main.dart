import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'services/notification_service.dart';

/// Application entry point
/// Initializes Riverpod state management and starts the app
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database for notification scheduling
  tz.initializeTimeZones();

  // Set local timezone (you can customize this or use device timezone)
  final String timeZoneName = DateTime.now().timeZoneName;
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Run app with Riverpod
  runApp(const ProviderScope(child: HappyTracksApp()));
}
