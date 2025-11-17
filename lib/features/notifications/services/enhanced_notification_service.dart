import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/database/database_service.dart';
import '../../../core/navigation/timeslot_navigator.dart';
import '../../../core/navigation/navigation_service.dart';
import '../models/notification_status.dart';
import 'notification_scheduler.dart';
import 'notification_health_monitor.dart';

/// Enhanced notification service with robust scheduling and health monitoring
///
/// Features:
/// - Tiered scheduling strategy (immediate + bootstrap)
/// - Health monitoring and diagnostics
/// - Automatic error recovery
/// - User-visible status tracking
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final NotificationScheduler _scheduler;
  late final NotificationHealthMonitor _healthMonitor;
  late final DatabaseService _database;

  bool _isInitialized = false;

  /// Initialize the enhanced notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️  EnhancedNotificationService already initialized');
      return;
    }

    debugPrint('🚀 Initializing EnhancedNotificationService...');

    // Initialize database service
    _database = DatabaseService();

    // Initialize scheduler and health monitor
    _scheduler = NotificationScheduler(_plugin);
    _healthMonitor = NotificationHealthMonitor(
      plugin: _plugin,
      database: _database,
    );

    // Android-specific initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS-specific initialization
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Manual control
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    // Initialize plugin with callback
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );

    _isInitialized = true;
    debugPrint('✅ EnhancedNotificationService initialized');

    // Perform initial health check
    await performHealthCheck();
  }

  /// Store callback for notification taps (will be set by app)
  static void Function(int timeIndex)? onNotificationTap;

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.id}');

    // Check if this is the bootstrap notification
    if (response.id == 9999) {
      debugPrint('🔄 Bootstrap notification detected - triggering bootstrap');
      _handleBootstrap();
      return;
    }

    // Extract time index from notification ID
    final timeIndex = TimeslotNavigator.extractTimeIndexFromNotificationId(
      response.id ?? 0,
    );

    if (timeIndex != null) {
      debugPrint('   Navigating to timeslot: $timeIndex');

      // Call the navigation callback if set
      onNotificationTap?.call(timeIndex);

      // Also try direct navigation if context is available
      if (NavigationService.currentContext != null) {
        TimeslotNavigator.navigateToTimeslot(
          context: NavigationService.currentContext!,
          timeIndex: timeIndex,
          openEditor: true,
        );
      }
    }
  }

  /// Handle background notification (runs even when app is terminated)
  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse response) {
    debugPrint('🌙 Background notification: ${response.id}');

    if (response.id == 9999) {
      // Bootstrap notification fired - schedule today's notifications
      // Note: This is limited in what it can do in background
      debugPrint('🔄 Bootstrap triggered in background');
    }
  }

  /// Handle bootstrap event to schedule today's notifications
  Future<void> _handleBootstrap() async {
    try {
      final settings = await _database.getSettings();

      if (settings.notificationsEnabled) {
        await _scheduler.handleBootstrapEvent(
          startHourIndex: settings.notificationStartHour,
          endHourIndex: settings.notificationEndHour,
        );

        // Update bootstrap timestamp
        await _database.updateSetting(
          'last_bootstrap_at',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('❌ Bootstrap failed: $e');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    debugPrint('🔔 Requesting notification permissions...');

    try {
      // iOS-specific permission request
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosPlugin != null) {
        final result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        final granted = result ?? false;
        debugPrint(granted
            ? '✅ iOS permissions granted'
            : '❌ iOS permissions denied');

        // Save permission status
        await _database.updateSetting('has_permission', granted.toString());
        return granted;
      }

      // Android permission request
      final status = await Permission.notification.request();
      final granted = status.isGranted;

      debugPrint(granted
          ? '✅ Android permissions granted'
          : '❌ Android permissions denied');

      // Save permission status
      await _database.updateSetting('has_permission', granted.toString());
      return granted;

    } catch (e) {
      debugPrint('❌ Permission request failed: $e');
      await _database.updateSetting('has_permission', 'false');
      return false;
    }
  }

  /// Schedule notifications with enhanced error handling
  Future<NotificationStatus> scheduleNotifications({
    required int startIndex,
    required int endIndex,
    required bool enabled,
  }) async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }

    debugPrint('📅 Enhanced notification scheduling started');

    try {
      // Clear any previous errors
      await _database.updateSettingNullable('last_error', null);

      // Use scheduler to set up notifications
      final status = await _scheduler.scheduleNotifications(
        startHourIndex: startIndex,
        endHourIndex: endIndex,
        isEnabled: enabled,
      );

      // Save status to database
      await _healthMonitor.saveHealthStatus(status);

      debugPrint('✅ Scheduling complete: ${status.scheduledCount} notifications');

      // Perform health check
      final health = await performHealthCheck();

      return health;

    } catch (e) {
      debugPrint('❌ Scheduling failed: $e');

      // Save error to database
      await _database.updateSetting('last_error', e.toString());

      // Return error status
      final errorStatus = NotificationStatus(
        isEnabled: enabled,
        hasPermission: false,
        scheduledCount: 0,
        lastError: e.toString(),
        lastScheduledAt: DateTime.now(),
        health: NotificationHealth.unhealthy,
      );

      await _healthMonitor.saveHealthStatus(errorStatus);

      return errorStatus;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    await _scheduler.cancelAllNotifications();

    // Update status
    await _database.updateSetting('scheduled_count', '0');
    await _database.updateSettingNullable('next_notification_time', null);
  }

  /// Perform health check
  Future<NotificationStatus> performHealthCheck() async {
    if (!_isInitialized) {
      return NotificationStatus.unknown();
    }

    final status = await _healthMonitor.checkHealth();
    debugPrint('🏥 Health: ${status.health.name} (${status.scheduledCount} scheduled)');

    return status;
  }

  /// Get diagnostic information
  Future<NotificationDiagnostics> getDiagnostics() async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }

    return await _healthMonitor.getDiagnostics();
  }

  /// Attempt to recover from unhealthy state
  Future<bool> attemptRecovery() async {
    if (!_isInitialized) return false;

    debugPrint('🔧 Attempting notification recovery...');

    // First try automatic recovery
    final canRecover = await _healthMonitor.attemptRecovery();

    if (canRecover) {
      // Get current settings and reschedule
      final settings = await _database.getSettings();

      if (settings.notificationsEnabled) {
        final status = await scheduleNotifications(
          startIndex: settings.notificationStartHour,
          endIndex: settings.notificationEndHour,
          enabled: true,
        );

        return status.health != NotificationHealth.unhealthy;
      }
    }

    return false;
  }

  /// Get current notification status
  Future<NotificationStatus> getStatus() async {
    if (!_isInitialized) {
      return NotificationStatus.unknown();
    }

    return await _healthMonitor.checkHealth();
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    return await _scheduler.getPendingNotifications();
  }

  /// Test fire a notification immediately (for debugging)
  Future<void> testNotification() async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      99999, // Test notification ID
      'Test Notification',
      'This is a test notification to verify the system is working',
      details,
    );

    debugPrint('🧪 Test notification fired');
  }
}