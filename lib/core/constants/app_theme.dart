import 'package:flutter/material.dart';

/// App theme definitions
/// Provides consistent styling across light and dark modes
class AppTheme {
  // ==================== Colors ====================

  // Light theme colors
  static const Color lightBackground = Color(0xFFFAFAFA); // Off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E5E5);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF1A1A1A); // Dark grey
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // ==================== Dimensions ====================

  // Tiered border radius system for visual hierarchy
  static const double borderRadius = 12.0; // Base radius - cards, containers, inputs
  static const double borderRadiusButton = 16.0; // Button radius - more friendly/accessible
  static const double borderRadiusLarge = 20.0; // Prominent elements - carousel cards
  static const double borderWidth = 1.0;

  // Spacing (8px base unit)
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  static const double spacing4 = 16.0;
  static const double spacing6 = 24.0;
  static const double spacing8 = 32.0;
  static const double spacing12 = 48.0;

  // Component sizes
  static const double timeslotHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeLarge = 32.0;

  // ==================== Text Styles ====================

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ==================== Theme Data ====================

  /// Create light theme with custom accent color
  static ThemeData lightTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: lightSurface,
        error: const Color(0xFFDC2626),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightText,
      ),

      // Scaffold
      scaffoldBackgroundColor: lightBackground,

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: lightBorder, width: borderWidth),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: borderWidth,
        space: 0,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: lightBorder, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: lightBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: accentColor, width: 2.0),
        ),
      ),

      // Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusButton),
            ),
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: headlineLarge,
        displayMedium: headlineMedium,
        displaySmall: headlineSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ).apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: lightText,
        size: iconSize,
      ),
    );
  }

  /// Create dark theme with custom accent color
  static ThemeData darkTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: darkSurface,
        error: const Color(0xFFEF4444),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),

      // Scaffold
      scaffoldBackgroundColor: darkBackground,

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: darkBorder, width: borderWidth),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: borderWidth,
        space: 0,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: darkBorder, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: darkBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: accentColor, width: 2.0),
        ),
      ),

      // Button themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusButton),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadiusButton),
            ),
          ),
        ),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: headlineLarge,
        displayMedium: headlineMedium,
        displaySmall: headlineSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
      ).apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: darkText,
        size: iconSize,
      ),
    );
  }
}
