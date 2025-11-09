import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../models/timeslot.dart';

/// Dialog for editing timeslot description and score
/// Allows user to add notes and adjust happiness score
class TimeslotEditorDialog extends StatefulWidget {
  final Timeslot timeslot;
  final Function(String? description, int score) onSave;

  const TimeslotEditorDialog({
    super.key,
    required this.timeslot,
    required this.onSave,
  });

  @override
  State<TimeslotEditorDialog> createState() => _TimeslotEditorDialogState();
}

class _TimeslotEditorDialogState extends State<TimeslotEditorDialog> {
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
                Icon(
                  Icons.edit_note,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: AppTheme.spacing2),
                Text(
                  widget.timeslot.time,
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            SizedBox(height: AppTheme.spacing4),

            // Happiness score slider
            Text(
              'Happiness Score',
              style: theme.textTheme.labelLarge,
            ),
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
                    divisions: 20, // 5-point increments for easier selection
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
                child: Text(
                  _score.toString(),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacing6),

            // Description input
            Text(
              'What were you doing?',
              style: theme.textTheme.labelLarge,
            ),
            SizedBox(height: AppTheme.spacing2),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
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
                FilledButton(
                  onPressed: _handleSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final description = _descriptionController.text.trim();
    widget.onSave(
      description.isEmpty ? null : description,
      _score,
    );
    Navigator.of(context).pop();
  }
}
