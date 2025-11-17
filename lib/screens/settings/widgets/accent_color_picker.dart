import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/spacing.dart';
import '../../../providers/settings_provider.dart';

/// Accent color picker widget
class AccentColorPicker extends ConsumerWidget {
  final Color currentColor;

  const AccentColorPicker({super.key, required this.currentColor});

  /// Predefined color palette
  static final List<Color> colorPalette = [
    const Color(0xFF6366F1), // Indigo (default)
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Green
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.spacing2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.color_lens_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                SizedBox(width: AppSpacing.spacing2),
                Text('Accent Color', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: AppSpacing.spacing2),
            Center(
              child: Wrap(
                spacing: AppSpacing.spacing2,
                runSpacing: AppSpacing.spacing2,
                alignment: WrapAlignment.center,
                children: colorPalette.map((color) {
                  // Compare colors using toARGB32()
                  final isSelected =
                      color.toARGB32() == currentColor.toARGB32();
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .updateAccentColor(color);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.borderRadius,
                        ),
                        border: isSelected
                            ? Border.all(
                                // Use subtle border matching home screen timeslot items
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: Colors.white, size: 32)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
