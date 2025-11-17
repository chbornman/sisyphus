// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$enhancedNotificationServiceHash() =>
    r'c60b10ad966bc93060e4abf8cf0f74bfcc1f8a61';

/// Provider for the enhanced notification service instance
/// This is a singleton that provides the same instance throughout the app
///
/// Copied from [enhancedNotificationService].
@ProviderFor(enhancedNotificationService)
final enhancedNotificationServiceProvider =
    Provider<EnhancedNotificationService>.internal(
      enhancedNotificationService,
      name: r'enhancedNotificationServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$enhancedNotificationServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EnhancedNotificationServiceRef =
    ProviderRef<EnhancedNotificationService>;
String _$notificationDiagnosticsHash() =>
    r'02344df6950907abf0116a6b17ace4d7c22cc3f2';

/// Provider for notification diagnostics
/// Provides detailed diagnostic information for troubleshooting
///
/// Copied from [notificationDiagnostics].
@ProviderFor(notificationDiagnostics)
final notificationDiagnosticsProvider =
    AutoDisposeFutureProvider<NotificationDiagnostics>.internal(
      notificationDiagnostics,
      name: r'notificationDiagnosticsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationDiagnosticsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationDiagnosticsRef =
    AutoDisposeFutureProviderRef<NotificationDiagnostics>;
String _$notificationsNeedAttentionHash() =>
    r'3bd5ea82ea98e976a9d81907a9f53e815c04f5a9';

/// Provider to check if notifications need attention
/// Returns true if health is degraded or unhealthy
///
/// Copied from [notificationsNeedAttention].
@ProviderFor(notificationsNeedAttention)
final notificationsNeedAttentionProvider = AutoDisposeProvider<bool>.internal(
  notificationsNeedAttention,
  name: r'notificationsNeedAttentionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsNeedAttentionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsNeedAttentionRef = AutoDisposeProviderRef<bool>;
String _$pendingNotificationCountHash() =>
    r'c2cdafc0ef5d7c2e36a9c77cdbe36e224c30dc6d';

/// Provider for pending notification count
/// Returns the number of scheduled notifications
///
/// Copied from [pendingNotificationCount].
@ProviderFor(pendingNotificationCount)
final pendingNotificationCountProvider = AutoDisposeProvider<int>.internal(
  pendingNotificationCount,
  name: r'pendingNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingNotificationCountRef = AutoDisposeProviderRef<int>;
String _$notificationStatusNotifierHash() =>
    r'c17dd8ad46fe19c9ebb9a5dbe3d0e5d26f3baefc';

/// Provider for notification status
/// Watches the current health and status of the notification system
///
/// Copied from [NotificationStatusNotifier].
@ProviderFor(NotificationStatusNotifier)
final notificationStatusNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      NotificationStatusNotifier,
      NotificationStatus
    >.internal(
      NotificationStatusNotifier.new,
      name: r'notificationStatusNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationStatusNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationStatusNotifier =
    AutoDisposeAsyncNotifier<NotificationStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
