import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../core/constants/app_theme.dart';
import 'settings_provider.dart';

part 'theme_provider.g.dart';

/// Provider for light theme
/// Watches settings to get accent color
@riverpod
ThemeData lightTheme(Ref ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) => AppTheme.lightTheme(settings.accentColor),
    loading: () => AppTheme.lightTheme(const Color(0xFF6366F1)), // Default indigo
    error: (_, __) => AppTheme.lightTheme(const Color(0xFF6366F1)),
  );
}

/// Provider for dark theme
/// Watches settings to get accent color
@riverpod
ThemeData darkTheme(Ref ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) => AppTheme.darkTheme(settings.accentColor),
    loading: () => AppTheme.darkTheme(const Color(0xFF6366F1)), // Default indigo
    error: (_, __) => AppTheme.darkTheme(const Color(0xFF6366F1)),
  );
}

/// Provider for theme mode
/// Watches settings to get user's theme preference
@riverpod
ThemeMode themeMode(Ref ref) {
  final settingsAsync = ref.watch(settingsProvider);

  return settingsAsync.when(
    data: (settings) => settings.themeMode,
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
}
