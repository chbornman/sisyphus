import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../models/timeslot.dart';
import '../../providers/settings_provider.dart';
import '../../providers/timeslot_provider.dart';
import 'timeslot_editor_dialog.dart';

/// Individual timeslot list item widget
/// Shows time, happiness score visualization, and description
class TimeslotListItem extends ConsumerStatefulWidget {
  final Timeslot timeslot;
  final bool isCurrentSlot;
  final bool isFuture;

  const TimeslotListItem({
    super.key,
    required this.timeslot,
    this.isCurrentSlot = false,
    this.isFuture = false,
  });

  @override
  ConsumerState<TimeslotListItem> createState() => _TimeslotListItemState();
}

class _TimeslotListItemState extends ConsumerState<TimeslotListItem> {
  // Track temporary score during drag
  int? _draggingScore;
  // Track starting values for relative drag
  int? _dragStartScore;
  double? _dragStartX;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Get accent color from settings, or use default
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    // Use dragging score if actively dragging, otherwise use saved score
    final displayScore = _draggingScore ?? widget.timeslot.happinessScore;
    final scoreColor = ColorUtils.getTimeslotColor(accentColor, displayScore);

    return Container(
      height: AppTheme.timeslotHeight,
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing4,
        vertical: AppTheme.spacing1,
      ),
      child: Row(
        children: [
          // Time label
          _buildTimeLabel(theme),

          SizedBox(width: AppTheme.spacing2),

          // Happiness score bar (draggable)
          Expanded(
            child: GestureDetector(
              // Horizontal drag to set score (relative) - disabled for future slots
              onHorizontalDragStart: widget.isFuture ? null : _handleDragStart,
              onHorizontalDragUpdate: widget.isFuture ? null : _handleDragUpdate,
              onHorizontalDragEnd: widget.isFuture ? null : _handleDragEnd,
              // Tap to open description editor - disabled for future slots
              onTap: widget.isFuture ? null : _openDescriptionEditor,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isFuture
                      ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                      : scoreColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                    color: theme.dividerColor,
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

                    // Description preview
                    if (widget.timeslot.description != null &&
                        widget.timeslot.description!.isNotEmpty)
                      Positioned(
                        left: AppTheme.spacing2,
                        top: 0,
                        bottom: 0,
                        right: displayScore > 0 ? 60 : AppTheme.spacing2,
                        child: Center(
                          child: _buildDescriptionPreview(theme),
                        ),
                      ),

                    // Empty state hint
                    if (displayScore == 0 &&
                        (widget.timeslot.description == null ||
                            widget.timeslot.description!.isEmpty))
                      Center(
                        child: Text(
                          widget.isFuture
                              ? 'Future timeslot'
                              : 'Drag to score • Tap to add note',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: widget.isFuture ? 0.3 : 0.4,
                            ),
                          ),
                        ),
                      ),

                    // Current time indicator
                    if (widget.isCurrentSlot)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AppTheme.borderRadius),
                              bottomLeft: Radius.circular(AppTheme.borderRadius),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build time label (e.g., "09:00", "09:30")
  Widget _buildTimeLabel(ThemeData theme) {
    return SizedBox(
      width: 60,
      child: Text(
        widget.timeslot.time,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: widget.isCurrentSlot ? FontWeight.w600 : FontWeight.normal,
          color: widget.isCurrentSlot
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(
                  alpha: widget.isFuture ? 0.3 : 0.6,
                ),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  /// Build score badge showing happiness number
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
          color: theme.dividerColor,
          width: AppTheme.borderWidth,
        ),
      ),
      child: Text(
        score.toString(),
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build description preview text
  Widget _buildDescriptionPreview(ThemeData theme) {
    return Text(
      widget.timeslot.description!,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Handle drag start - capture starting position and score
  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragStartScore = widget.timeslot.happinessScore;
      _dragStartX = details.localPosition.dx;
      _draggingScore = widget.timeslot.happinessScore;
    });
  }

  /// Handle horizontal drag update - relative to start position
  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStartScore == null || _dragStartX == null) return;

    // Get the width of the draggable area
    final RenderBox box = context.findRenderObject() as RenderBox;
    final width = box.size.width - 60 - AppTheme.spacing2; // Subtract time label width

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

  /// Handle drag end - save score to database
  void _handleDragEnd(DragEndDetails details) {
    if (_draggingScore != null) {
      // Save score to database via Riverpod (optimistic update)
      ref.read(timeslotsProvider.notifier).updateScore(
            widget.timeslot.timeIndex,
            _draggingScore!,
          );
    }

    // Reset drag state
    setState(() {
      _draggingScore = null;
      _dragStartScore = null;
      _dragStartX = null;
    });
  }

  /// Open description editor dialog
  void _openDescriptionEditor() {
    showDialog(
      context: context,
      builder: (context) => TimeslotEditorDialog(
        timeslot: widget.timeslot,
        onSave: (description, score) {
          // Save both description and score
          ref.read(timeslotsProvider.notifier).updateTimeslot(
                widget.timeslot.timeIndex,
                score,
                description,
              );
        },
      ),
    );
  }
}
