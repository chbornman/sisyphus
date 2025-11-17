import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_provider.g.dart';

/// Model for deep link navigation requests
class DeepLinkRequest {
  final int timeIndex;
  final bool openEditor;
  final DateTime timestamp;

  DeepLinkRequest({
    required this.timeIndex,
    required this.openEditor,
  }) : timestamp = DateTime.now();
}

/// Provider for managing deep link navigation requests
///
/// Used to communicate navigation requests from notifications
/// to the home screen for proper scrolling and modal opening
@riverpod
class DeepLinkNotifier extends _$DeepLinkNotifier {
  @override
  DeepLinkRequest? build() => null;

  /// Request navigation to a specific timeslot
  void navigateToTimeslot({
    required int timeIndex,
    bool openEditor = true,
  }) {
    state = DeepLinkRequest(
      timeIndex: timeIndex,
      openEditor: openEditor,
    );
  }

  /// Clear the current deep link request
  void clear() {
    state = null;
  }
}