import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Application entry point
/// Initializes Riverpod state management and starts the app
void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Run app with Riverpod
  runApp(
    const ProviderScope(
      child: HappyTracksApp(),
    ),
  );
}
