import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/navigation_service.dart';
import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';

/// Root app widget
/// Sets up theme and routing
class SisyphusApp extends ConsumerWidget {
  const SisyphusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme providers
    final lightThemeData = ref.watch(lightThemeProvider);
    final darkThemeData = ref.watch(darkThemeProvider);
    final themeModeValue = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Sisyphus',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.navigatorKey,

      // Theme configuration
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: themeModeValue,

      // Initial route
      home: const HomeScreen(),
    );
  }
}
