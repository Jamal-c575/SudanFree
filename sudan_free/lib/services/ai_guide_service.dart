import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/common/ai_page_guide_widget.dart';

class AiGuideService {
  static const String _cachePrefix = 'ai_guide_cache_';
  static const String _seenPrefix = 'ai_guide_seen_';

  // API Config (Using Groq)
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  /// Show the AI Guide for a specific page.
  /// If [forceShow] is true, it ignores the "already seen" flag.
  static Future<void> showPageGuide(BuildContext context, String pageName, String userName, {bool forceShow = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user has already seen this page's guide
    final bool hasSeen = prefs.getBool('$_seenPrefix$pageName') ?? false;
    if (hasSeen && !forceShow) return;

    // Check if we have cached text for this page
    String? cachedText = prefs.getString('$_cachePrefix$pageName');
    
    if (cachedText == null || cachedText.isEmpty) {
      // Generate dynamically from AI
      cachedText = await _generateGuideText(pageName, userName);
      if (cachedText.isNotEmpty) {
        await prefs.setString('$_cachePrefix$pageName', cachedText);
      } else {
        // Fallback default message
        cachedText = 'مرحباً $userName! استكشف ميزات هذه الصفحة واستفد من خدمات التطبيق.';
      }
    }

    // Mark as seen
    await prefs.setBool('$_seenPrefix$pageName', true);

    if (!context.mounted) return;

    // Show the floating bubble
    _showFloatingBubble(context, cachedText);
  }

  static Future<String> _generateGuideText(String pageName, String userName) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'أنت المساعد الذكي لتطبيق سودان فري (SudanFree)، واسمك Home. قم بصياغة رسالة ترحيبية قصيرة جداً (سطر واحد فقط) للمستخدم، واشرح فيها بشكل ذكي وودود ميزة الصفحة التي يزورها الآن. يجب أن تكون اللهجة سودانية خفيفة وراقية.'
            },
            {'role': 'user', 'content': 'اسم المستخدم: $userName\nاسم الصفحة التي دخلها: $pageName'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['choices'][0]['message']['content'] ?? '';
        return textResponse.trim().replaceAll('"', '');
      }
      return '';
    } catch (e) {
      debugPrint('Error generating AI Guide: $e');
      return '';
    }
  }

  static void _showFloatingBubble(BuildContext context, String message) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AiPageGuideWidget(
        message: message,
        onDismiss: () {
          overlayEntry?.remove();
          overlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry!);

    // Auto dismiss after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (overlayEntry != null && overlayEntry!.mounted) {
        overlayEntry?.remove();
        overlayEntry = null;
      }
    });
  }
}
