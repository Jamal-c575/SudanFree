import 'package:flutter/material.dart';
import 'smooth_route.dart';

class NavigationUtils {
  static Widget? pendingScreen;
  static bool isHomeScreenReady = false;

  /// Navigates safely by ensuring the Home Screen is ready.
  /// If it is not ready, queues the screen to be shown once the Home Screen is built.
  static void navigateSafely(BuildContext? context, Widget screen) {
    if (context != null && context.mounted && isHomeScreenReady) {
      Navigator.push(context, SmoothRoute(page: screen));
    } else {
      pendingScreen = screen;
    }
  }

  /// Called by HomeScreen when it is successfully loaded.
  static void onHomeScreenReady(BuildContext context) {
    isHomeScreenReady = true;
    if (pendingScreen != null) {
      final screen = pendingScreen!;
      pendingScreen = null;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          Navigator.push(context, SmoothRoute(page: screen));
        }
      });
    }
  }
}
