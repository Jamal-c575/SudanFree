import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/ai_service.dart';
import '../../widgets/ai/voice_record_button.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';

class DailyOfferPopup extends StatefulWidget {
  const DailyOfferPopup({super.key});

  /// Check if the popup should be shown (max 3 times a day)
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastShowDate = prefs.getString('daily_offer_date');
    
    if (lastShowDate != today) {
      await prefs.setString('daily_offer_date', today);
      await prefs.setInt('daily_offer_count', 1);
      return true;
    }
    
    final count = prefs.getInt('daily_offer_count') ?? 0;
    if (count < 3) {
      await prefs.setInt('daily_offer_count', count + 1);
      return true;
    }
    
    return false;
  }

  static void show(BuildContext context) {
    shouldShow().then((show) {
      if (show && context.mounted) {
        showDialog(
          context: context,
          builder: (_) => const DailyOfferPopup(),
        );
      }
    });
  }

  @override
  State<DailyOfferPopup> createState() => _DailyOfferPopupState();
}

class _DailyOfferPopupState extends State<DailyOfferPopup> {
  bool _isLoading = true;
  String _aiOfferSummary = '';

  @override
  void initState() {
    super.initState();
    _fetchAiSummary();
  }

  Future<void> _fetchAiSummary() async {
    final summary = await AiService().sendIsolatedMessage(
      'أنت مساعد ترويجي لتطبيق سودان فري. مهمتك الوحيدة هي كتابة رسائل ترويجية قصيرة وجذابة تشجع المستخدمين على طلب الخدمات عبر التطبيق. استخدم أسلوباً ودياً باللهجة السودانية. لا تكتب أكثر من ٣ جمل.',
      'اكتب عرضاً ترويجياً مبهجاً يشجع المستخدمين على طلب خدمات اليوم من تطبيق سودان فري.',
    );

    if (mounted) {
      setState(() {
        _aiOfferSummary = summary.isNotEmpty
            ? summary
            : 'اليوم عندك فرصة! ابحث عن الحرفي المناسب في سودان فري وطلب خدمتك بسرعة وأمان. 🌟';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.read<LocaleProvider>().isArabic;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.local_offer, size: 64, color: AppColors.primary),
            const SizedBox(height: 16.0),
            Text(
              isArabic ? 'عروض اليوم الخاصة! 🌟' : "Today's Special Offers! 🌟",
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    _aiOfferSummary,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16.0),
                  ),
            const SizedBox(height: 32.0),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    isArabic
                        ? 'احتاج خدمة حسع؟ اضغط وسجل طلبك بصوتك!'
                        : 'Need a service now? Press to record your request!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  VoiceRecordButton(
                    onResult: (text) {
                      Navigator.pop(context); // Close popup
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تحويل طلبك: $text')),
                      );
                      // Here you can navigate to CreatePostScreen with the text
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // To close the dialog
                },
                child: Text(isArabic ? 'إغلاق' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
