import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

/// Root app widget
/// Sets up theme and routing
class HappyTracksApp extends ConsumerWidget {
  const HappyTracksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme providers
    final lightThemeData = ref.watch(lightThemeProvider);
    final darkThemeData = ref.watch(darkThemeProvider);
    final themeModeValue = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'HappyTracks',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: themeModeValue,

      // Initial route
      home: const HomeScreen(),
    );
  }
}
