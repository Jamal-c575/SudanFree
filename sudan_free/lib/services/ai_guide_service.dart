import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/common/ai_page_guide_widget.dart';

class AiGuideService {
  static const String _cachePrefix = 'ai_guide_cache_';
  static const String _seenPrefix = 'ai_guide_seen_';
  static bool isWelcomeDialogShowing = false;
  static OverlayEntry? _currentOverlay;
  static final Set<String> _inProgressPages = {};

  /// خريطة تفصيلية لكل صفحة — تصف ما تفعله الصفحة بالضبط
  static const Map<String, String> _pageContextMap = {
    'الصفحة الرئيسية': 'الصفحة الرئيسية تعرض ملخص سريع لكل اللي بيصير في التطبيق: الإحصائيات، المنشورات الجديدة، العروض، والطلبات النشطة. منها تقدر توصل لجميع أقسام التطبيق.',
    'خريطة الحرفيين': 'شاشة الخريطة التفاعلية بتعرض مواقع الحرفيين ومقدمي الخدمات اللي قريبين منك. تقدر تضغط على أي علامة تشوف تفاصيل الحرفي وتتواصل معه على طول.',
    'المجتمع': 'شاشة المجتمع بتعرض منشورات الحرفيين وأعمالهم ومنتجاتهم. تقدر تعجب وتعلق وتتفاعل مع المنشورات، وكمان تنشر منشوراتك الخاصة.',
    'طلبات الخدمة': 'شاشة الطلبات بتعرض طلبات الخدمات المفتوحة من الزبائن اللي بدورون على حرفيين. لو أنت حرفي، تقدر تقدم عروض على الطلبات وتاخد الشغل.',
    'الإشعارات': 'شاشة الإشعارات بتعرض كل التحديثات المهمة: ردود التعليقات، قبول العروض، رسايل جديدة، طلبات شراكة، وتقييمات جديدة.',
    'الدردشة': 'شاشة الدردشة للتواصل المباشر مع الزبائن والحرفيين. تقدر ترسل رسايل ونصوص وصور ومستندات لتسهيل إتمام الصفقات.',
    'الحرفيون': 'شاشة الحرفيين بتعرض قايمة بمقدمي الخدمات المتاحين مع إمكانية الفلترة حسب التخصص والتقييم والموقع.',
    'المتاجر': 'شاشة المتاجر بتعرض قايمة المتاجر المسجلة في التطبيق مع منتجاتها. تقدر تتصفح وتتواصل مع أصحاب المتاجر مباشرة.',
    'الوظائف': 'شاشة الوظائف بتعرض فرص العمل المفتوحة اللي بينشرها أصحاب العمل. الحرفيين يقدروا يتقدموا لهذه الفرص.',
    'الملف الشخصي': 'الملف الشخصي بيعرض معلوماتك الكاملة: مهاراتك، أعمالك السابقة، التقييمات، ومعرض أعمالك. تقدر تعدل بياناتك وتشوف إحصائياتك.',
    'الإعدادات': 'شاشة الإعدادات بتخليك تخصص التطبيق: تغيير اللغة، الإشعارات، الخصوصية، وإدارة حسابك.',
    'تتبع العمل': 'شاشة تتبع العمل بتعرض مراحل المشروع الحالي وتقدمه. تقدر تحدث المراحل وتتواصل مع الطرف الثاني للتنسيق.',
    'الاتفاقيات': 'شاشة الاتفاقيات بتعرض كل العقود والصفقات اللي بين الزبائن والحرفيين. تقدر تراجع التفاصيل وتتابع حالة كل اتفاقية.',
    'المفضلة': 'شاشة المفضلة بتعرض الحرفيين والمتاجر والمنشورات اللي حفظتها لتسهيل الوصول إليها في أي وقت.',
    'نصائح الأمان': 'شاشة نصائح الأمان بتقدم إرشادات مهمة لحمايتك من الاحتيال وكيف تتعامل بأمان في التطبيق.',
    'إنشاء منتج': 'شاشة إنشاء منتج بتخليك تنشر منتجاتك وخدماتك بصور وأسعار ووصف تفصيلي لعرضها في المجتمع.',
  };

  /// الحصول على وصف الصفحة من الخريطة أو إرجاع الاسم مباشرة
  static String _getPageContext(String pageName) {
    // البحث عن تطابق جزئي في الخريطة
    for (final entry in _pageContextMap.entries) {
      if (pageName.contains(entry.key) || entry.key.contains(pageName)) {
        return entry.value;
      }
    }
    return 'صفحة "$pageName" في تطبيق سودان فري لخدمات الحرفيين.';
  }

  /// Show the AI Guide for a specific page.
  /// If [forceShow] is true, it ignores the "already seen" flag.
  static Future<void> showPageGuide(BuildContext context, String pageName, String userName, {bool forceShow = false}) async {
    if (_inProgressPages.contains(pageName)) return;
    _inProgressPages.add(pageName);

    try {
      while (isWelcomeDialogShowing) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has already seen this page's guide
      final bool hasSeen = prefs.getBool('$_seenPrefix$pageName') ?? false;
      if (hasSeen && !forceShow) return;

      if (!forceShow) {
        // Mark as seen immediately to prevent concurrent calls
        await prefs.setBool('$_seenPrefix$pageName', true);
      }

      // Check if we have cached text for this page
      String? cachedText = prefs.getString('$_cachePrefix$pageName');
      
      if (cachedText == null || cachedText.isEmpty) {
        // Generate dynamically from AI
        cachedText = await _generateGuideText(pageName, userName);
        if (cachedText.isNotEmpty) {
          await prefs.setString('$_cachePrefix$pageName', cachedText);
        } else {
          // Fallback بالعامية السودانية
          cachedText = _getSudaneseFallback(pageName, userName);
        }
      }

      if (!context.mounted) return;

      // Show the floating bubble
      _showFloatingBubble(context, cachedText);
    } finally {
      _inProgressPages.remove(pageName);
    }
  }

  static Future<String> _generateGuideText(String pageName, String userName) async {
    try {
      final pageContext = _getPageContext(pageName);
      final callable = FirebaseFunctions.instance.httpsCallable('ai_generatePageGuide');
      
      final result = await callable.call({
        'pageName': pageName,
        'userName': userName,
        'pageContext': pageContext,
      });
      
      final data = result.data as Map<String, dynamic>;
      final text = data['guide'] as String? ?? '';
      return _sanitizeGuideOutput(text.trim().replaceAll('"', ''));
    } catch (e) {
      debugPrint('Error generating AI Guide: $e');
      return '';
    }
  }

  /// فلتر الحروف الأجنبية لمخرجات المرشد الذكي.
  /// يحذف أي حرف غير عربي أو إنجليزي أو رقم أو علامة ترقيم أو إيموجي.
  static String _sanitizeGuideOutput(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final cp = rune;
      // العربية
      if (cp >= 0x0600 && cp <= 0x06FF) { buffer.writeCharCode(cp); continue; }
      if (cp >= 0x0750 && cp <= 0x077F) { buffer.writeCharCode(cp); continue; }
      if (cp >= 0xFB50 && cp <= 0xFDFF) { buffer.writeCharCode(cp); continue; }
      if (cp >= 0xFE70 && cp <= 0xFEFF) { buffer.writeCharCode(cp); continue; }
      // اللاتينية الأساسية (إنجليزي، أرقام، ترقيم، مسافة)
      if (cp >= 0x0020 && cp <= 0x007E) { buffer.writeCharCode(cp); continue; }
      // سطر جديد / تبويب
      if (cp == 0x000A || cp == 0x000D || cp == 0x0009) { buffer.writeCharCode(cp); continue; }
      // الإيموجي الشائعة
      if (cp >= 0x1F300 && cp <= 0x1FAFF) { buffer.writeCharCode(cp); continue; }
      if (cp >= 0x2600 && cp <= 0x27BF) { buffer.writeCharCode(cp); continue; }
      if (cp >= 0x1F900 && cp <= 0x1F9FF) { buffer.writeCharCode(cp); continue; }
      // علامات الاتجاه (مفيدة للعربية)
      if (cp == 0x200C || cp == 0x200D || cp == 0x200E || cp == 0x200F) { buffer.writeCharCode(cp); continue; }
      // أي شيء آخر = ممنوع (صيني، ياباني، روسي...)
    }
    return buffer.toString().replaceAll(RegExp(r' {3,}'), '  ').trim();
  }

  static void _showFloatingBubble(BuildContext context, String message) {
    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => AiPageGuideWidget(
        message: message,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);

    // Auto dismiss after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (_currentOverlay != null && _currentOverlay!.mounted) {
        _currentOverlay?.remove();
        _currentOverlay = null;
      }
    });
  }

  /// رسائل الـ fallback باللهجة السودانية — تُستخدم لو فشل الـ API
  static String _getSudaneseFallback(String pageName, String userName) {
    final Map<String, String> fallbacks = {
      'الصفحة الرئيسية':    'أهلاً $userName! من هنا تقدر تشوف كل شي — الحرفيين، الطلبات، والمجتمع 👋',
      'خريطة الحرفيين':     'كيف $userName! الخريطة دي تورّيك الحرفيين القريبين منك، اضغط على أي واحد 📍',
      'المجتمع':             'يا سلام يا $userName! هنا منشورات وأعمال الحرفيين، تفاعل وشارك بيها 🎨',
      'طلبات الخدمة':       '$userName لو عندك مهارة، هنا طلبات الزبائن — قدم عرضك وامشي 💼',
      'الإشعارات':          'في جديد يا $userName! شوف إشعاراتك هنا 🔔',
      'الدردشة':            'يا $userName! من هنا تتواصل مع الزبائن والحرفيين مباشرة 💬',
      'الحرفيون':           '$userName هنا كل الحرفيين المتاحين — فلتر وابحث اللي تريده 🔍',
      'المتاجر':            'يا $userName! هنا المتاجر والمنتجات — تصفح وتواصل مع التجار 🏪',
      'الوظائف':            '$userName! هنا فرص العمل المفتوحة — قدّم وخذ الشغل 💪',
      'الملف الشخصي':       'هذا ملفك يا $userName! عدّل بياناتك واعرض أعمالك 👤',
      'الإعدادات':          '$userName من هنا تضبط التطبيق زي ما تريد ⚙️',
      'تتبع العمل':         'يا $userName! هنا تتابع مراحل شغلك وتنسق مع العميل 📊',
      'الاتفاقيات':         '$userName هنا كل صفقاتك واتفاقياتك في مكان واحد 📄',
      'المفضلة':            'يا $userName! هنا اللي حفظته من حرفيين ومنشورات ⭐',
      'نصائح الأمان':       '$userName! اقرأ النصائح دي عشان تتعامل بأمان في التطبيق 🛡️',
      'إنشاء منتج':         '$userName انشر منتجك أو خدمتك هنا وخلّي الناس تشوفك 🚀',
    };
    // بحث جزئي
    for (final entry in fallbacks.entries) {
      if (pageName.contains(entry.key) || entry.key.contains(pageName)) {
        return entry.value;
      }
    }
    return 'أهلاً $userName! تفضل في "$pageName" 👋';
  }
}
