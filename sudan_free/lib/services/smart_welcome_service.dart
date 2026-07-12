import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudan_free/services/update_service.dart';
import 'package:sudan_free/widgets/common/smart_welcome_dialog.dart';
import 'package:sudan_free/services/ai_guide_service.dart';

class SmartWelcomeService {
  static const String _countKey = 'welcome_shown_count';
  static const String _dateKey = 'welcome_last_shown_date';
  static const String _lastTimeKey = 'welcome_last_shown_timestamp';

  static Future<void> checkAndShow(BuildContext context) async {
    AiGuideService.isWelcomeDialogShowing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? lastDateStr = prefs.getString(_dateKey);
      final int count = prefs.getInt(_countKey) ?? 0;
      final int lastTimeMs = prefs.getInt(_lastTimeKey) ?? 0;
      
      final DateTime now = DateTime.now();
      final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Minimum interval of 2 hours to not annoy the user
      final bool hasEnoughTimePassed = (now.millisecondsSinceEpoch - lastTimeMs) > const Duration(hours: 2).inMilliseconds;

      int newCount = count;
      if (lastDateStr != todayStr) {
        newCount = 0; // Reset count for the new day
      }

      // Show at most 4 times a day, and only if 2 hours have passed since the last time
      if (newCount < 4 && (hasEnoughTimePassed || lastTimeMs == 0)) {
        newCount++;
        await prefs.setInt(_countKey, newCount);
        await prefs.setString(_dateKey, todayStr);
        await prefs.setInt(_lastTimeKey, now.millisecondsSinceEpoch);
        
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black54,
            builder: (context) => const SmartWelcomeDialog(),
          );
        }
      }

      // Check for updates after handling welcome dialog
      if (context.mounted) {
        UpdateService.checkForUpdate(context);
      }
    } catch (e) {
      debugPrint('Error in SmartWelcomeService: $e');
      if (context.mounted) {
        UpdateService.checkForUpdate(context);
      }
    } finally {
      AiGuideService.isWelcomeDialogShowing = false;
    }
  }
}
