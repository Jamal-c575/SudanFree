import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudan_free/services/update_service.dart';
import 'package:sudan_free/widgets/common/smart_welcome_dialog.dart';

class SmartWelcomeService {
  static const String _countKey = 'welcome_shown_count';
  static const String _dateKey = 'welcome_last_shown_date';

  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final String? lastDateStr = prefs.getString(_dateKey);
      final int count = prefs.getInt(_countKey) ?? 0;
      
      final DateTime now = DateTime.now();
      final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      int newCount = count;
      if (lastDateStr != todayStr) {
        newCount = 0;
      }

      if (newCount < 3) {
        newCount++;
        await prefs.setInt(_countKey, newCount);
        await prefs.setString(_dateKey, todayStr);
        
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
    }
  }
}
