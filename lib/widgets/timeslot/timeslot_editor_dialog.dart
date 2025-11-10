import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
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

    // Get time format from settings
    final timeFormat = ref
        .watch(settingsProvider)
        .when(
          data: (settings) => settings.timeFormat,
          loading: () => TimeFormat.twelveHour,
          error: (_, __) => TimeFormat.twelveHour,
        );

    // Format time according to user preference
    final formattedTime = TimeUtils.formatTimeForDisplay(
      widget.timeslot.timeIndex,
      timeFormat,
    );

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

            // Happiness score slider
            Text('Happiness Score', style: theme.textTheme.labelLarge),
            SizedBox(height: AppTheme.spacing2),

            Row(
              children: [
                Text(
                  '0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _score.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100, // 1-point increments for precise selection
                    label: _score.toString(),
                    onChanged: (value) {
                      setState(() {
                        _score = value.round();
                      });
                    },
                  ),
                ),
                Text(
                  '100',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),

            // Current score display
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing4,
                  vertical: AppTheme.spacing2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
                child: SizedBox(
                  width: 80, // Fixed width to prevent size changes
                  child: Text(
                    _score.toString(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
}
