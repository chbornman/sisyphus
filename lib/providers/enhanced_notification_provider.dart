import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/notifications/services/enhanced_notification_service.dart';
import '../features/notifications/models/notification_status.dart';
import '../features/notifications/services/notification_health_monitor.dart';

part 'enhanced_notification_provider.g.dart';

/// Provider for the enhanced notification service instance
/// This is a singleton that provides the same instance throughout the app
@Riverpod(keepAlive: true)
EnhancedNotificationService enhancedNotificationService(
    EnhancedNotificationServiceRef ref) {
  return EnhancedNotificationService();
}

/// Provider for notification status
/// Watches the current health and status of the notification system
@riverpod
class NotificationStatusNotifier extends _$NotificationStatusNotifier {
  @override
  Future<NotificationStatus> build() async {
    final service = ref.read(enhancedNotificationServiceProvider);

    // Get current status
    return await service.getStatus();
  }

  /// Refresh notification status
  Future<void> refresh() async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(enhancedNotificationServiceProvider);
      final status = await service.performHealthCheck();
      state = AsyncValue.data(status);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Schedule notifications
  Future<void> scheduleNotifications({
    required int startIndex,
    required int endIndex,
    required bool enabled,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = ref.read(enhancedNotificationServiceProvider);
      final status = await service.scheduleNotifications(
        startIndex: startIndex,
        endIndex: endIndex,
        enabled: enabled,
      );
      state = AsyncValue.data(status);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Attempt recovery if unhealthy
  Future<bool> attemptRecovery() async {
    try {
      final service = ref.read(enhancedNotificationServiceProvider);
      final recovered = await service.attemptRecovery();

      if (recovered) {
        // Refresh status after recovery
        await refresh();
      }

      return recovered;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Test notification
  Future<void> testNotification() async {
    final service = ref.read(enhancedNotificationServiceProvider);
    await service.testNotification();
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    final service = ref.read(enhancedNotificationServiceProvider);
    await service.cancelAllNotifications();
    await refresh();
  }
}

/// Provider for notification diagnostics
/// Provides detailed diagnostic information for troubleshooting
@riverpod
Future<NotificationDiagnostics> notificationDiagnostics(
    NotificationDiagnosticsRef ref) async {
  final service = ref.read(enhancedNotificationServiceProvider);
  return await service.getDiagnostics();
}

/// Provider to check if notifications need attention
/// Returns true if health is degraded or unhealthy
@riverpod
bool notificationsNeedAttention(NotificationsNeedAttentionRef ref) {
  final statusAsync = ref.watch(notificationStatusNotifierProvider);

  return statusAsync.maybeWhen(
    data: (status) =>
        status.health == NotificationHealth.unhealthy ||
        status.health == NotificationHealth.degraded,
    orElse: () => false,
  );
}

/// Provider for pending notification count
/// Returns the number of scheduled notifications
@riverpod
int pendingNotificationCount(PendingNotificationCountRef ref) {
  final statusAsync = ref.watch(notificationStatusNotifierProvider);

  return statusAsync.maybeWhen(
    data: (status) => status.scheduledCount,
    orElse: () => 0,
  );
}