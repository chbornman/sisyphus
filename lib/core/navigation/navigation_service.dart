import 'package:flutter/material.dart';

/// Global navigation service for handling navigation without context
///
/// Used primarily for deep linking from notifications and background tasks
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Navigate to a route
  static Future<T?>? navigateTo<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to home and clear stack
  static Future<T?>? navigateToHome<T>() {
    return navigator?.pushNamedAndRemoveUntil<T>('/', (route) => false);
  }

  /// Get current context
  static BuildContext? get currentContext => navigator?.context;
}