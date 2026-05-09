import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../core/constants/app_colors.dart';

class UpdateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Fetch minimum required version from Firestore
      final doc = await _firestore.collection('app_config').doc('main').get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final minVersion = data['min_version'] as String?;
      final storeUrl = data['store_url'] as String?;

      if (minVersion == null || storeUrl == null) return;

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isUpdateRequired(currentVersion, minVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, storeUrl);
        }
      }
    } catch (e) {
      debugPrint('UpdateService check error: $e');
    }
  }

  static bool _isUpdateRequired(String currentVersion, String minVersion) {
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    final minParts = minVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < minParts.length; i++) {
      if (i >= currentParts.length) return true; // Current is shorter
      if (currentParts[i] < minParts[i]) return true; // Current is older
      if (currentParts[i] > minParts[i]) return false; // Current is newer
    }
    return false; // Versions are equal
  }

  static void _showUpdateDialog(BuildContext context, String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force update
      builder: (context) {
        final isArabic = context.read<LocaleProvider>().isArabic;
        return PopScope(
          canPop: false, // Prevent back button
          child: AlertDialog(
            title: Text(
              isArabic ? 'تحديث إجباري' : 'Update Required',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            content: Text(
              isArabic 
                  ? 'نسختك الحالية قديمة جداً. يرجى تحديث التطبيق للمتابعة واستخدام أحدث الميزات بأمان.'
                  : 'Your app version is too old. Please update to continue using the app safely.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(storeUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(isArabic ? 'تحديث الآن' : 'Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}
