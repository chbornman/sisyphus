import 'package:flutter/material.dart';

/// Color palette for light and dark themes
class AppColors {
  AppColors._();

  // ==================== Light Theme Colors ====================

  /// Light theme background - Off-white
  static const Color lightBackground = Color(0xFFFAFAFA);

  /// Light theme surface - Pure white
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light theme primary text
  static const Color lightText = Color(0xFF1A1A1A);

  /// Light theme secondary text
  static const Color lightTextSecondary = Color(0xFF6B7280);

  /// Light theme border color
  static const Color lightBorder = Color(0xFFE5E5E5);

  /// Light theme error color
  static const Color lightError = Color(0xFFDC2626);

  // ==================== Dark Theme Colors ====================

  /// Dark theme background - Dark grey
  static const Color darkBackground = Color(0xFF1A1A1A);

  /// Dark theme surface
  static const Color darkSurface = Color(0xFF2A2A2A);

  /// Dark theme primary text
  static const Color darkText = Color(0xFFFAFAFA);

  /// Dark theme secondary text
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  /// Dark theme border color
  static const Color darkBorder = Color(0xFF3A3A3A);

  /// Dark theme error color
  static const Color darkError = Color(0xFFEF4444);
}
