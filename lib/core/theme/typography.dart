import 'package:flutter/material.dart';

/// Typography styles for consistent text appearance
class AppTypography {
  AppTypography._();

  // ==================== Headlines ====================

  /// Large headline - 32px bold
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  /// Medium headline - 24px bold
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
  );

  /// Small headline - 20px semi-bold
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );

  // ==================== Body Text ====================

  /// Large body text - 16px
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  /// Medium body text - 14px
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  /// Small body text - 12px
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
  );

  // ==================== Labels ====================

  /// Large label - 14px semi-bold
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Medium label - 12px semi-bold
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
