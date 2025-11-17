import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/color_utils.dart';
import '../../models/app_settings.dart';
import '../../models/timeslot.dart';
import '../../providers/settings_provider.dart';
import '../../providers/timeslot_provider.dart';
import 'components/time_label.dart';
import 'components/timeslot_score_bar.dart';
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
  /// Track temporary score during drag
  int? _draggingScore;
  /// Track starting values for relative drag
  int? _dragStartScore;
  double? _dragStartX;

  /// Animation controller for current timeslot transition
  late AnimationController _currentSlotAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  /// Track previous isCurrentSlot state to detect changes
  bool _wasCurrentSlot = false;

  @override
  void initState() {
    super.initState();
    _wasCurrentSlot = widget.isCurrentSlot;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _currentSlotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation: 1.0 -> 1.15 -> 1.0 (subtle pop)
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

    if (widget.isCurrentSlot) {
      _currentSlotAnimationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TimeslotListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCurrentSlot && !_wasCurrentSlot) {
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

    final displayScore = _draggingScore ?? widget.timeslot.happinessScore;
    final scoreColor = ColorUtils.getTimeslotColor(accentColor, displayScore);

    return Container(
      height: AppSpacing.timeslotHeight,
      color: widget.isOutsideNotificationHours
          ? theme.colorScheme.onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05,
            )
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing1,
      ),
      child: Row(
        children: [
          Expanded(
            child: TimeslotScoreBar(
              displayScore: displayScore,
              description: widget.timeslot.description,
              isFuture: widget.isFuture,
              scoreColor: scoreColor,
              onTap: _openDescriptionEditor,
              onDragStart: _handleDragStart,
              onDragUpdate: _handleDragUpdate,
              onDragEnd: _handleDragEnd,
            ),
          ),
          SizedBox(width: AppSpacing.spacing2),
          TimeLabel(
            timeIndex: widget.timeslot.timeIndex,
            timeFormat: timeFormat,
            isCurrentSlot: widget.isCurrentSlot,
            isFuture: widget.isFuture,
            accentColor: accentColor,
            scaleAnimation: _scaleAnimation,
            fadeAnimation: _fadeAnimation,
            animationController: _currentSlotAnimationController,
          ),
        ],
      ),
    );
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragStartScore = widget.timeslot.happinessScore;
      _dragStartX = details.localPosition.dx;
      _draggingScore = widget.timeslot.happinessScore;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStartScore == null || _dragStartX == null) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final width = box.size.width - 60 - AppSpacing.spacing2;
    final deltaX = details.localPosition.dx - _dragStartX!;
    final deltaScore = (deltaX / width * 200).round();
    final newScore = (_dragStartScore! + deltaScore).clamp(0, 100);

    setState(() {
      _draggingScore = newScore;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_draggingScore != null) {
      ref.read(timeslotsProvider.notifier).updateScore(
            widget.timeslot.timeIndex,
            _draggingScore!,
          );
    }

    setState(() {
      _draggingScore = null;
      _dragStartScore = null;
      _dragStartX = null;
    });
  }

  void _openDescriptionEditor() {
    showDialog(
      context: context,
      builder: (context) => TimeslotEditorDialog(
        timeslot: widget.timeslot,
        onSave: (description, score) {
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
