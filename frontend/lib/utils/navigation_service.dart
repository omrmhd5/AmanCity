import 'package:flutter/material.dart';

class Navigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Navigate to a named route
  static Future<dynamic>? goTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and replace current route (better for tab navigation)
  static Future<dynamic>? goToReplacement(
    String routeName, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Navigate and remove all previous routes
  static Future<dynamic>? goToClearAll(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  /// Navigate and remove routes until condition is met
  static Future<dynamic>? goToUntil(
    String routeName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Go back to previous screen
  static void goBack({dynamic result}) {
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState?.pop(result);
    }
  }

  /// Check if can go back
  static bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  /// Pop until route name
  static void popUntil(String routeName) {
    navigatorKey.currentState?.popUntil(ModalRoute.withName(routeName));
  }

  /// Navigate with animation
  static Future<dynamic>? goToWithAnimation(
    String routeName, {
    Object? arguments,
    required Duration duration,
  }) {
    return navigatorKey.currentState?.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Remove all routes and go to home
  static Future<dynamic>? goHome() {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/',
      (Route<dynamic> route) => false,
    );
  }

  /// Get current route name
  static String? getCurrentRouteName() {
    String? routeName;
    navigatorKey.currentState?.popUntil((route) {
      routeName = route.settings.name;
      return true;
    });
    return routeName;
  }

  /// Navigate using replacement (ideal for tab navigation)
  /// Replaces current route instead of pushing, preventing stack buildup
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }

  /// Pop and navigate (handles cases where you want to go back then forward)
  static void popAndNavigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.popAndPushNamed(routeName, arguments: arguments);
  }
}
