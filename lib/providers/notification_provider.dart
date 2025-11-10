import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:happy_tracks/services/notification_service.dart';

part 'notification_provider.g.dart';

/// Provider for NotificationService singleton
/// Manages local notification scheduling and permissions
@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}
