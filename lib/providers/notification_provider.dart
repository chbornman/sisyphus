import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sisyphus/services/notification_service.dart';

part 'notification_provider.g.dart';

/// Provider for NotificationService singleton
/// Manages local notification scheduling and permissions
@riverpod
NotificationService notificationService(Ref ref) {
  return NotificationService();
}
