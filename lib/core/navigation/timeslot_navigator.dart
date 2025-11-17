import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/timeslot.dart';
import '../../providers/timeslot_provider.dart';
import '../../widgets/timeslot/timeslot_editor_dialog.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/time_utils.dart';
import '../../core/utils/date_utils.dart';

/// Navigation utility for scrolling to and opening specific timeslots
///
/// This provides a centralized way to:
/// 1. Navigate to the home screen
/// 2. Scroll to a specific timeslot
/// 3. Open the editor dialog for that timeslot
///
/// Used by notifications and other features that need to deep-link to timeslots
class TimeslotNavigator {
  /// Navigate to a specific timeslot on today's date and open its editor
  ///
  /// Parameters:
  /// - context: Build context for navigation
  /// - timeIndex: The timeslot index (0-47) to navigate to
  /// - scrollController: Optional scroll controller if already on home screen
  /// - openEditor: Whether to open the editor dialog after scrolling
  static Future<void> navigateToTimeslot({
    required BuildContext context,
    required int timeIndex,
    ScrollController? scrollController,
    bool openEditor = true,
  }) async {
    // Ensure we're on the home screen
    // If not already there, navigate to it
    if (ModalRoute.of(context)?.settings.name != '/') {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

      // Wait a frame for navigation to complete
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // If we have a scroll controller, scroll to the timeslot
    if (scrollController != null && scrollController.hasClients) {
      await _scrollToTimeslot(scrollController, timeIndex);

      // Wait for scroll animation to complete
      await Future.delayed(const Duration(milliseconds: 600));
    }

    // Open the editor dialog if requested
    if (openEditor && context.mounted) {
      await _openTimeslotEditor(context, timeIndex);
    }
  }

  /// Scroll to a specific timeslot index with animation
  static Future<void> _scrollToTimeslot(
    ScrollController controller,
    int timeslotIndex,
  ) async {
    if (!controller.hasClients) return;

    // Calculate scroll position
    // Account for top spacer plus timeslot height for each item
    final topSpacerHeight = AppSpacing.spacing2;
    final itemHeight = AppSpacing.timeslotHeight;
    final targetPosition = topSpacerHeight + (timeslotIndex * itemHeight);

    // Scroll to position with some offset to center it better
    final maxScroll = controller.position.maxScrollExtent;
    final scrollPosition = (targetPosition - 100).clamp(0.0, maxScroll);

    await controller.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  /// Open the editor dialog for a specific timeslot
  static Future<void> _openTimeslotEditor(
    BuildContext context,
    int timeIndex,
  ) async {
    // Get the current date (today)
    final today = DateTime.now();
    final dateString = AppDateUtils.toDbFormat(today);

    // Create or get the timeslot
    final timeslot = Timeslot(
      date: dateString,
      timeIndex: timeIndex,
      time: TimeUtils.indexToTime(timeIndex),
      happinessScore: 0, // Will be loaded from database if exists
      createdAt: today,
      updatedAt: today,
    );

    // Show the editor dialog
    await showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          // Get the actual timeslot data from provider if it exists
          final timeslotsAsync = ref.watch(timeslotsProvider);
          final actualTimeslot = timeslotsAsync.maybeWhen(
            data: (timeslots) {
              try {
                return timeslots.firstWhere(
                  (t) => t.timeIndex == timeIndex,
                );
              } catch (_) {
                return timeslot;
              }
            },
            orElse: () => timeslot,
          );

          return TimeslotEditorDialog(
            timeslot: actualTimeslot,
            onSave: (description, score) {
              // Save both description and score
              ref.read(timeslotsProvider.notifier).updateTimeslot(
                    timeIndex,
                    score,
                    description,
                  );
            },
          );
        },
      ),
    );
  }

  /// Extract timeslot index from notification payload
  ///
  /// Notification IDs are formatted as: dayOffset * 100 + timeIndex
  /// So we extract the timeIndex from the ID
  static int? extractTimeIndexFromNotificationId(int notificationId) {
    // Bootstrap notification has ID 9999
    if (notificationId == 9999) return null;

    // Extract time index from notification ID
    // IDs are formatted as: sequence * 100 + timeIndex
    final timeIndex = notificationId % 100;

    // Validate time index is in valid range
    if (timeIndex >= 0 && timeIndex < 48) {
      return timeIndex;
    }

    return null;
  }

  /// Navigate to timeslot from notification tap
  ///
  /// This is a convenience method specifically for handling notification taps
  static Future<void> navigateFromNotification({
    required BuildContext context,
    required int notificationId,
    ScrollController? scrollController,
  }) async {
    final timeIndex = extractTimeIndexFromNotificationId(notificationId);

    if (timeIndex != null) {
      await navigateToTimeslot(
        context: context,
        timeIndex: timeIndex,
        scrollController: scrollController,
        openEditor: true,
      );
    }
  }
}