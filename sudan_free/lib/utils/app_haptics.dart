import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

/// AppHaptics: A centralized utility to handle haptic feedback.
/// It uses the `vibration` package to directly access the device vibrator hardware,
/// bypassing Android system settings if Touch Vibration is disabled, similar to Telegram.
class AppHaptics {
  /// Checks if the device has a vibrator.
  static Future<bool> get _hasVibrator async {
    final hasVibrator = await Vibration.hasVibrator();
    return hasVibrator ?? false;
  }

  /// Light impact (e.g. for small buttons, switches)
  static Future<void> lightImpact() async {
    if (await _hasVibrator) {
      // Increased further to 40ms/140amp for better noticeability as requested
      Vibration.vibrate(duration: 40, amplitude: 140);
    } else {
      // Fallback for devices without direct access
      HapticFeedback.lightImpact();
    }
  }

  /// Medium impact (e.g. for standard buttons, important actions)
  static Future<void> mediumImpact() async {
    if (await _hasVibrator) {
      Vibration.vibrate(duration: 50, amplitude: 180);
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  /// Heavy impact (e.g. for errors, destructive actions)
  static Future<void> heavyImpact() async {
    if (await _hasVibrator) {
      Vibration.vibrate(duration: 60, amplitude: 255);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  /// Selection click (e.g. for pickers, bottom navigation)
  static Future<void> selectionClick() async {
    if (await _hasVibrator) {
      // Increased to 20ms/90amp to make it noticeable but still light
      Vibration.vibrate(duration: 20, amplitude: 90);
    } else {
      HapticFeedback.selectionClick();
    }
  }
}
