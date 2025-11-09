import 'dart:ui';
import '../constants/app_constants.dart';

/// Utility functions for color manipulation and happiness score visualization
class ColorUtils {
  /// Calculate opacity based on happiness score
  /// Linear interpolation from 0 (transparent) to 100 (fully opaque)
  /// Each point increases opacity by 1%
  static double scoreToOpacity(int score) {
    if (score < AppConstants.minHappinessScore ||
        score > AppConstants.maxHappinessScore) {
      throw ArgumentError('Score must be between 0 and 100');
    }

    if (score == 0) return 0.0;

    // Linear interpolation: score 1-100 maps to opacity 0.2-1.0
    // This gives a minimum visible opacity of 20% for score of 1
    // and 100% opacity for score of 100
    return (0.2 + (score / 100) * 0.8).clamp(0.2, 1.0);
  }

  /// Apply opacity to a color based on happiness score
  static Color applyScoreOpacity(Color color, int score) {
    final opacity = scoreToOpacity(score);
    return color.withValues(alpha: opacity);
  }

  /// Parse hex color string to Color object
  /// Supports formats: "#RRGGBB" or "RRGGBB"
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert Color to hex string
  /// Returns format: "#RRGGBB"
  static String toHex(Color color) {
    final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  /// Get a color for a timeslot based on happiness score
  /// Combines accent color with score-based opacity
  static Color getTimeslotColor(Color accentColor, int score) {
    return applyScoreOpacity(accentColor, score);
  }

  /// Calculate average opacity from multiple scores
  /// Useful for displaying average happiness in calendar cells
  static double averageOpacity(List<int> scores) {
    if (scores.isEmpty) return 0.0;

    final validScores = scores.where((s) => s > 0).toList();
    if (validScores.isEmpty) return 0.0;

    final avgScore = validScores.reduce((a, b) => a + b) / validScores.length;
    return scoreToOpacity(avgScore.round());
  }
}
