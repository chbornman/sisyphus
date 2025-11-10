import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/time_utils.dart';
import '../../models/app_settings.dart';
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
  final bool isOutsideNotificationHours;

  const TimeslotListItem({
    super.key,
    required this.timeslot,
    this.isCurrentSlot = false,
    this.isFuture = false,
    this.isOutsideNotificationHours = false,
  });

  @override
  ConsumerState<TimeslotListItem> createState() => _TimeslotListItemState();
}

class _TimeslotListItemState extends ConsumerState<TimeslotListItem>
    with SingleTickerProviderStateMixin {
  // Track temporary score during drag
  int? _draggingScore;
  // Track starting values for relative drag
  int? _dragStartScore;
  double? _dragStartX;

  // Animation controller for current timeslot transition
  late AnimationController _currentSlotAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Track previous isCurrentSlot state to detect changes
  bool _wasCurrentSlot = false;

  @override
  void initState() {
    super.initState();
    _wasCurrentSlot = widget.isCurrentSlot;

    // Initialize animation controller
    _currentSlotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation: 1.0 -> 1.1 -> 1.0 (subtle pop)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70.0,
      ),
    ]).animate(_currentSlotAnimationController);

    // Fade animation: 0.0 -> 1.0 (fade in)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _currentSlotAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // If this is already the current slot on init, show it immediately
    if (widget.isCurrentSlot) {
      _currentSlotAnimationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TimeslotListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Detect when this timeslot becomes current
    if (widget.isCurrentSlot && !_wasCurrentSlot) {
      // Just became current - trigger animation
      _currentSlotAnimationController.forward(from: 0.0);
    }

    _wasCurrentSlot = widget.isCurrentSlot;
  }

  @override
  void dispose() {
    _currentSlotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Get settings values, or use defaults
    final accentColor = settingsAsync.when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    final timeFormat = settingsAsync.when(
      data: (settings) => settings.timeFormat,
      loading: () => TimeFormat.twelveHour,
      error: (_, __) => TimeFormat.twelveHour,
    );

    // Use dragging score if actively dragging, otherwise use saved score
    final displayScore = _draggingScore ?? widget.timeslot.happinessScore;
    final scoreColor = ColorUtils.getTimeslotColor(accentColor, displayScore);

    // Wrap entire timeslot for consistent layout
    return Container(
      height: AppTheme.timeslotHeight,
      // Add darker background for hours outside notification range
      // Similar to Google Calendar's nighttime hours styling - full-width stripe
      color: widget.isOutsideNotificationHours
          ? theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
            )
          : null,
      // Use padding instead of margin for consistent vertical spacing
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing4,
        vertical: AppTheme.spacing1,
      ),
      child: Row(
        children: [
          // Time label
          _buildTimeLabel(theme, timeFormat),

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

                    // Empty state hint (not shown for future timeslots)
                    if (displayScore == 0 &&
                        (widget.timeslot.description == null ||
                            widget.timeslot.description!.isEmpty) &&
                        !widget.isFuture)
                      Center(
                        child: Text(
                          'Drag to score • Tap to add note',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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

  /// Build time label (e.g., "09:00", "9:00 AM")
  /// Format depends on user's time format preference
  Widget _buildTimeLabel(ThemeData theme, TimeFormat timeFormat) {
    final formattedTime = TimeUtils.formatTimeForDisplay(
      widget.timeslot.timeIndex,
      timeFormat,
    );

    // Get accent color from settings for current slot indicator
    final accentColor = ref.watch(settingsProvider).when(
      data: (settings) => settings.accentColor,
      loading: () => theme.colorScheme.primary,
      error: (_, __) => theme.colorScheme.primary,
    );

    final timeLabel = Text(
      formattedTime,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: widget.isCurrentSlot ? FontWeight.w600 : FontWeight.normal,
        color: widget.isCurrentSlot
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(
                alpha: widget.isFuture ? 0.3 : 0.6,
              ),
      ),
      textAlign: TextAlign.center,
    );

    final content = widget.isCurrentSlot
        ? Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing1,
              vertical: AppTheme.spacing1,
            ),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: timeLabel,
          )
        : Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing1),
            child: timeLabel,
          );

    return SizedBox(
      width: timeFormat == TimeFormat.twelveHour ? 75 : 60,
      child: widget.isCurrentSlot
          ? AnimatedBuilder(
              animation: _currentSlotAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: content,
            )
          : content,
    );
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
