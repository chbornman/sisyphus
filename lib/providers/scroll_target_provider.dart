import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scroll_target_provider.g.dart';

/// Provider for tracking target timeslot to scroll to
/// Used when navigating from analysis screen to home screen
@riverpod
class ScrollTarget extends _$ScrollTarget {
  @override
  int? build() {
    return null; // No target by default
  }

  /// Set target timeslot index to scroll to
  void setTarget(int? timeIndex) {
    state = timeIndex;
  }

  /// Clear the target after scrolling
  void clearTarget() {
    state = null;
  }
}
