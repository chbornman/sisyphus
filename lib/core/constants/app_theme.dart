import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/theme_data.dart';
import '../theme/typography.dart';

/// App theme definitions - DEPRECATED
///
/// This class maintains backward compatibility with existing code.
/// New code should import from `../theme/app_theme.dart` directly:
/// - [AppColors] for color constants
/// - [AppSpacing] for spacing and dimensions
/// - [AppTypography] for text styles
/// - [AppThemeData] for theme creation methods
@Deprecated('Use AppColors, AppSpacing, AppTypography, and AppThemeData instead')
class AppTheme {
  // ==================== Colors (delegated to AppColors) ====================

  static const Color lightBackground = AppColors.lightBackground;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightText = AppColors.lightText;
  static const Color lightTextSecondary = AppColors.lightTextSecondary;
  static const Color lightBorder = AppColors.lightBorder;

  static const Color darkBackground = AppColors.darkBackground;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkText = AppColors.darkText;
  static const Color darkTextSecondary = AppColors.darkTextSecondary;
  static const Color darkBorder = AppColors.darkBorder;

  // ==================== Dimensions (delegated to AppSpacing) ====================

  static const double borderRadius = AppSpacing.borderRadius;
  static const double borderRadiusButton = AppSpacing.borderRadiusButton;
  static const double borderRadiusLarge = AppSpacing.borderRadiusLarge;
  static const double borderWidth = AppSpacing.borderWidth;

  static const double spacing1 = AppSpacing.spacing1;
  static const double spacing2 = AppSpacing.spacing2;
  static const double spacing3 = AppSpacing.spacing3;
  static const double spacing4 = AppSpacing.spacing4;
  static const double spacing6 = AppSpacing.spacing6;
  static const double spacing8 = AppSpacing.spacing8;
  static const double spacing12 = AppSpacing.spacing12;

  static const double timeslotHeight = AppSpacing.timeslotHeight;
  static const double appBarHeight = AppSpacing.appBarHeight;
  static const double iconSize = AppSpacing.iconSize;
  static const double iconSizeSmall = AppSpacing.iconSizeSmall;
  static const double iconSizeLarge = AppSpacing.iconSizeLarge;

  // ==================== Text Styles (delegated to AppTypography) ====================

  static const TextStyle headlineLarge = AppTypography.headlineLarge;
  static const TextStyle headlineMedium = AppTypography.headlineMedium;
  static const TextStyle headlineSmall = AppTypography.headlineSmall;
  static const TextStyle bodyLarge = AppTypography.bodyLarge;
  static const TextStyle bodyMedium = AppTypography.bodyMedium;
  static const TextStyle bodySmall = AppTypography.bodySmall;
  static const TextStyle labelLarge = AppTypography.labelLarge;
  static const TextStyle labelMedium = AppTypography.labelMedium;

  // ==================== Theme Data (delegated to AppThemeData) ====================

  /// Create light theme with custom accent color
  static ThemeData lightTheme(Color accentColor) =>
      AppThemeData.lightTheme(accentColor);

  /// Create dark theme with custom accent color
  static ThemeData darkTheme(Color accentColor) =>
      AppThemeData.darkTheme(accentColor);
}
