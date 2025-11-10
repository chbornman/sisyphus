import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/time_utils.dart';
import '../../models/app_settings.dart';
import '../../models/timeslot.dart';
import '../../providers/settings_provider.dart';

/// Dialog for editing timeslot description and score
/// Allows user to add notes and adjust happiness score
class TimeslotEditorDialog extends ConsumerStatefulWidget {
  final Timeslot timeslot;
  final Function(String? description, int score) onSave;

  const TimeslotEditorDialog({
    super.key,
    required this.timeslot,
    required this.onSave,
  });

  @override
  ConsumerState<TimeslotEditorDialog> createState() =>
      _TimeslotEditorDialogState();
}

class _TimeslotEditorDialogState extends ConsumerState<TimeslotEditorDialog> {
  late TextEditingController _descriptionController;
  late int _score;

  // Track temporary score during drag
  int? _draggingScore;
  // Track starting values for relative drag
  int? _dragStartScore;
  double? _dragStartX;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.timeslot.description,
    );
    _score = widget.timeslot.happinessScore;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get settings from provider
    final settingsAsync = ref.watch(settingsProvider);

    // Get accent color
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    // Get time format from settings
    final timeFormat = settingsAsync.when(
      data: (settings) => settings.timeFormat,
      loading: () => TimeFormat.twelveHour,
      error: (_, __) => TimeFormat.twelveHour,
    );

    // Format time according to user preference
    final formattedTime = TimeUtils.formatTimeForDisplay(
      widget.timeslot.timeIndex,
      timeFormat,
    );

    // Use dragging score if actively dragging, otherwise use current score
    final displayScore = _draggingScore ?? _score;
    final scoreColor = ColorUtils.getTimeslotColor(accentColor, displayScore);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: EdgeInsets.all(AppTheme.spacing6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit_note, color: theme.colorScheme.primary),
                SizedBox(width: AppTheme.spacing2),
                Text(formattedTime, style: theme.textTheme.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacing4),

            // Happiness score slider bar (visual slider like main page)
            Text('Happiness Score', style: theme.textTheme.labelLarge),
            SizedBox(height: AppTheme.spacing3),

            GestureDetector(
              onHorizontalDragStart: _handleDragStart,
              onHorizontalDragUpdate: _handleDragUpdate,
              onHorizontalDragEnd: _handleDragEnd,
              child: Container(
                height: AppTheme.timeslotHeight - (AppTheme.spacing1 * 2), // 56 - 8 = 48px
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    width: AppTheme.borderWidth,
                  ),
                ),
                child: Stack(
                  children: [
                    // Score badge
                    if (displayScore > 0)
                      Positioned(
                        right: AppTheme.spacing2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _buildScoreBadge(displayScore, theme),
                        ),
                      ),

                    // Drag hint
                    if (displayScore == 0)
                      Center(
                        child: Text(
                          'Drag left or right to score',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacing6),

            // Description input
            Text('What were you doing?', style: theme.textTheme.labelLarge),
            SizedBox(height: AppTheme.spacing2),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),

            SizedBox(height: AppTheme.spacing6),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: AppTheme.spacing2),
                FilledButton(onPressed: _handleSave, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final description = _descriptionController.text.trim();
    widget.onSave(description.isEmpty ? null : description, _score);
    Navigator.of(context).pop();
  }

  /// Build score badge showing happiness number
  /// Fixed width to prevent size changes as digits increase
  Widget _buildScoreBadge(int score, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing2,
        vertical: AppTheme.spacing1,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          width: AppTheme.borderWidth,
        ),
      ),
      child: SizedBox(
        width: 32, // Fixed width to accommodate "100"
        child: Text(
          score.toString(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Handle drag start - capture starting position and score
  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragStartScore = _score;
      _dragStartX = details.localPosition.dx;
      _draggingScore = _score;
    });
  }

  /// Handle horizontal drag update - relative to start position
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStartScore == null || _dragStartX == null) return;

    // Get the width of the draggable area
    final RenderBox box = context.findRenderObject() as RenderBox;
    final width = box.size.width;

    // Calculate delta from start position
    final deltaX = details.localPosition.dx - _dragStartX!;

    // Convert delta to score change (full width = 100 points)
    final deltaScore = (deltaX / width * 100).round();

    // Apply delta to starting score
    final newScore = (_dragStartScore! + deltaScore).clamp(0, 100);

    setState(() {
      _draggingScore = newScore;
    });
  }

  /// Handle drag end - save score
  void _handleDragEnd(DragEndDetails details) {
    if (_draggingScore != null) {
      setState(() {
        _score = _draggingScore!;
        _draggingScore = null;
        _dragStartScore = null;
        _dragStartX = null;
      });
    }
  }
}
