import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _audioUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  final String _model = 'llama-3.3-70b-versatile';
  late String _apiKey;
  
  final List<Map<String, String>> _chatHistory = [];
  
  // Rate Limiting
  final List<DateTime> _messageTimestamps = [];
  static const int _maxMessagesPerMinute = 5;

  SharedPreferences? _prefs;

  AiService._internal() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null) {
      throw Exception('GROQ_API_KEY is missing from .env file.');
    }
    _apiKey = apiKey;
    
    // Default synchronous init so history is never totally null.
    // Real load happens via loadSavedHistory()
    _initHistory();
  }

  void _initHistory() {
    _chatHistory.clear();
    _chatHistory.add(_buildSystemPrompt());
  }

  void clearHistory() {
    _chatHistory.clear();
    _chatHistory.add(_buildSystemPrompt());
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('ai_chat_last_date', DateTime.now().toIso8601String());
    await _prefs!.setString('ai_chat_history', jsonEncode(_chatHistory));
  }

  /// Loads history from shared preferences, checking if it's the same day.
  /// Returns only the 'user' and 'assistant' messages for UI building.
  Future<List<Map<String, String>>> loadSavedHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    final lastDateStr = _prefs!.getString('ai_chat_last_date');
    bool shouldReset = true;

    if (lastDateStr != null) {
      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final now = DateTime.now();
        // Reset if it's past 1 AM and the last saved chat was before 1 AM today (or earlier days)
        // A simple way to represent "Chat day" is to subtract 1 hour from current time.
        // So anything from 1:00 AM today to 0:59 AM tomorrow is the same "Chat Day".
        final chatDayNow = now.subtract(const Duration(hours: 1));
        final chatDayLast = lastDate.subtract(const Duration(hours: 1));
        
        if (chatDayNow.year == chatDayLast.year && 
            chatDayNow.month == chatDayLast.month && 
            chatDayNow.day == chatDayLast.day) {
          shouldReset = false;
        }
      }
    }

    if (shouldReset) {
      clearHistory();
      return [];
    } else {
      final historyStr = _prefs!.getString('ai_chat_history');
      if (historyStr != null) {
        try {
          final List<dynamic> decoded = jsonDecode(historyStr);
          _chatHistory.clear();
          for (var item in decoded) {
            _chatHistory.add(Map<String, String>.from(item));
          }
        } catch (_) {
          clearHistory();
          return [];
        }
      }
      
      return _chatHistory.where((msg) => msg['role'] == 'user' || msg['role'] == 'assistant').toList();
    }
  }

  Map<String, String> _buildSystemPrompt() => {
    'role': 'system',
    'content': '''
أنت "Home" - المساعد الذكي الرسمي لتطبيق سودان فري (SudanFree).
تحدث دائماً بعربية فصحى مبسطة وسليمة.

═══ معلومات التطبيق ═══
- المؤسسة: Jhome
- المؤسس: جمال أحمد
- الموقع الرسمي: www.sudanfree.com
- الهدف: ربط العملاء بالحرفيين ومقدمي الخدمات في السودان.

═══ الموضوعات المسموح بها ═══
١. البحث عن حرفيين، متاجر، مجموعات خدمية، وظائف، وطلبات خدمة داخل التطبيق.
٢. تفاصيل ملفات الحرفيين: الاسم، التقييم، النبذة، المهارات، الموقع، الحالة.
٣. النصائح العامة عن سوق العمل الحر في السودان (الأسعار التقريبية للمهن، كيفية اختيار حرفي جيد، نصائح لكتابة طلب خدمة، نصائح للحرفيين لتحسين ملفاتهم).
٤. كيفية استخدام ميزات التطبيق المختلفة.
٥. معلومات مؤسسة Jhome والمؤسس جمال أحمد.

═══ المحظورات وكيفية التعامل معها ═══
المحظورات: السياسة، الأخبار، الدين والفتاوى، الرياضة، التعليم (حل واجبات أو جداول دراسية)، الطبخ والوصفات العامة، الترفيه.
عند السؤال عن أي محظور:
- قل فقط: "هذا خارج نطاق عملي."
- ثم حوّل مباشرة: "هل تحتاج مساعدة في البحث عن خدمة ما؟"
- لا تشرح، لا تعتذر، لا تذكر كلمة محظور.

═══ أدوات البحث ═══
عندما يطلب المستخدم بيانات من التطبيق، ضع في السطر الأول من ردك:
[TOOL: اسم_الأداة | الاستعلام]

الأدوات المتاحة:
- [TOOL: searchFreelancers | كلمة] — بحث عن حرفيين بالاسم أو التخصص
- [TOOL: searchShops | كلمة] — بحث عن متاجر
- [TOOL: searchJobs | كلمة] — بحث عن وظائف مفتوحة
- [TOOL: getTopRated | تخصص] — أعلى الحرفيين تقييماً
- [TOOL: getUserProfile | userId] — ملف شخص بمعرّفه
- [TOOL: searchSquads | كلمة] — بحث عن مجموعات خدمية
- [TOOL: getSquadProfile | squadId] — عرض بيانات ملف المجموعة الكاملة
- [TOOL: getSquadMembers | squadId] — استخراج قائمة أسماء أعضاء المجموعة الخدمية
- [TOOL: searchRequests | كلمة] — بحث عن طلبات خدمة نشطة

أمثلة:
- "أريد مبرمج" → [TOOL: searchFreelancers | برمجة]
- "ابحث عن تاج السر" → [TOOL: searchFreelancers | تاج السر]
- "من أفضل نجار؟" → [TOOL: getTopRated | نجارة]
- "هل هناك طلبات تنظيف؟" → [TOOL: searchRequests | تنظيف]
- "ابحث عن فريق مقاولات" → [TOOL: searchSquads | مقاولات]
- "ما فرص العمل في التصميم؟" → [TOOL: searchJobs | تصميم]

النظام سيُرسل لك البيانات الحقيقية من Firestore. قدّمها بشكل منظم: الاسم، التقييم، الحالة (متاح/مشغول)، الموقع، والنبذة إن وُجدت.

تحذير هام جداً وقاعدة صارمة: 
يُمنع منعاً باتاً اختلاق أو تأليف أي معلومات أو أسماء لأشخاص، متاجر، خدمات، أو مجموعات غير موجودة في البيانات التي يُرسلها لك النظام.
إذا طلب المستخدم شخصاً معيناً أو خدمة ولم يُرجع النظام أي بيانات حقيقية حوله، يجب أن تخبر المستخدم بوضوح: "عذراً، لم أتمكن من العثور على [الاسم/الخدمة] في قاعدة البيانات الحالية."
وظيفتك هي فقط صياغة وتحسين عرض البيانات المرجعة لك، ولا يحق لك إضافة أي بيانات من خارج التطبيق.
'''
  };

  bool _isRateLimited() {
    final now = DateTime.now();
    _messageTimestamps.removeWhere((timestamp) => now.difference(timestamp).inSeconds > 60);
    if (_messageTimestamps.length >= _maxMessagesPerMinute) {
      return true;
    }
    _messageTimestamps.add(now);
    return false;
  }

  Future<String> sendMessage(String text) async {
    if (_isRateLimited()) {
      return 'عذراً، لقد تجاوزت الحد المسموح به من الرسائل (5 رسائل كل دقيقة). يرجى الانتظار قليلاً لحماية استقرار النظام. 🛡️';
    }

    _chatHistory.add({'role': 'user', 'content': text});
    _saveHistory();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = data['choices'][0]['message']['content'] as String;
        final filtered = _filterResponse(responseText);
        
        // If it's a tool call, we don't save it to history immediately
        // The subsequent context response will be saved instead.
        if (!filtered.contains('[TOOL:')) {
          _chatHistory.add({'role': 'assistant', 'content': filtered});
          _saveHistory();
        }
        
        return filtered;
      } else {
        return 'حدث خطأ في النظام الذكي. رمز الخطأ: ${response.statusCode}';
      }
    } catch (e) {
      return 'عذراً، حدث خطأ أثناء الاتصال بالمساعد الذكي: $e';
    }
  }


  /// Sends a hidden context message to the AI (with real DB data) and gets a formatted response.
  /// The context is injected as a "tool" message — invisible to the user but seen by the model.
  /// The AI response is added to history normally.
  Future<String> sendContextMessage(String contextData) async {
    final messagesWithContext = [
      ..._chatHistory,
      {'role': 'user', 'content': contextData},
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messagesWithContext,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final responseText = data['choices'][0]['message']['content'] as String;
        // Add the polished assistant response to history
        _chatHistory.add({'role': 'assistant', 'content': responseText});
        _saveHistory();
        return responseText;
      } else {
        return 'حدث خطأ في النظام. رمز الخطأ: ${response.statusCode}';
      }
    } catch (e) {
      return 'عذراً، حدث خطأ في الاتصال: $e';
    }
  }

  /// Dart-side safety filter — last line of defense.
  /// If the model's response contains off-topic content, replace with a redirect.
  String _filterResponse(String response) {
    const offTopicKeywords = [
      'صلاة', 'صيام', 'حكومة', 'سياسة', 'انتخاب', 'حزب',
      'مباراة', 'كرة القدم', 'دوري', 'واجب', 'جدول دراسي',
      'وصفة طبخ', 'أغنية', 'فيلم', 'مسلسل',
    ];
    final lower = response.toLowerCase();
    for (final keyword in offTopicKeywords) {
      if (lower.contains(keyword)) {
        return 'هذا خارج نطاق عملي.\nهل تحتاج مساعدة في البحث عن خدمة ما؟';
      }
    }
    return response;
  }

  /// Sends a fully isolated message — no shared history, custom system prompt.
  /// Used for background AI tasks like daily offer popup. Safe and independent.
  Future<String> sendIsolatedMessage(String systemPrompt, String userMessage) async {
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
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content']?.trim() ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<String> enhanceText(String originalText) async {
    if (originalText.trim().isEmpty) return originalText;

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
              'content': 'الرجاء إعادة صياغة النص التالي ليكون أكثر احترافية، تسويقياً وجذاباً لخدمات العمل الحر. صحح الأخطاء وأرجع النص النهائي فقط بدون أي مقدمات.'
            },
            {'role': 'user', 'content': originalText}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content']?.trim() ?? originalText;
      }
      return originalText;
    } catch (e) {
      return originalText;
    }
  }

  Future<Map<String, dynamic>> analyzeSearchQuery(String query) async {
    if (query.trim().isEmpty) return {'category': null, 'keywords': []};

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'response_format': {"type": "json_object"},
          'messages': [
            {
              'role': 'system',
              'content': 'قم بتحليل الجملة التالية واستخراج نية البحث الخاصة بالخدمات. الرجاء الرد بتنسيق JSON حصراً بالشكل التالي:\n{"category": "اسم التصنيف الأقرب أو null", "keywords": ["كلمة1"]}'
            },
            {'role': 'user', 'content': query}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['choices'][0]['message']['content'] ?? '';
        final cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
      return {'category': null, 'keywords': [query]};
    } catch (e) {
      return {'category': null, 'keywords': [query]};
    }
  }

  Future<String> transcribeAudioToServiceRequest(String audioFilePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_audioUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-large-v3';
      request.fields['prompt'] = 'This is an Arabic request for a freelance service. Please transcribe it clearly.';
      request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final transcribedText = data['text'] ?? '';
        // Enhance it
        return await enhanceText(transcribedText);
      } else {
        return 'لم أتمكن من تحويل الصوت. تأكد من جودة التسجيل.';
      }
    } catch (e) {
      return 'حدث خطأ أثناء معالجة الصوت: $e';
    }
  }

  Future<double> estimateSmartPrice(String jobDescription, double baseAveragePrice) async {
    if (jobDescription.trim().isEmpty) return baseAveragePrice;

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
              'content': 'أنت خبير تسعير خدمات مهنية في السودان. متوسط السعر العادي: $baseAveragePrice جنيه. بناءً على الوصف، قيم التعقيد. إذا كان معقداً ارفع السعر، وإذا بسيط قلله. أرجع رقماً فقط يمثل السعر الجديد بدون أي نص أو فواصل.'
            },
            {'role': 'user', 'content': jobDescription}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['choices'][0]['message']['content'] ?? '';
        final priceStr = textResponse.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(priceStr) ?? baseAveragePrice;
      }
      return baseAveragePrice;
    } catch (e) {
      return baseAveragePrice;
    }
  }

  Future<Map<String, dynamic>> analyzeOfferSafety(String offerText, String requestText) async {
    if (offerText.trim().isEmpty) return {'isSafe': true, 'reason': 'لا يوجد نص للتحليل'};

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'response_format': {"type": "json_object"},
          'messages': [
            {
              'role': 'system',
              'content': 'أنت خبير أمني في كشف الاحتيال والنصب في منصات العمل الحر في السودان. قم بتحليل هذا العرض المقدم لطلب عميل. العروض المشبوهة هي التي تطلب التواصل عبر تطبيقات خارجية (تليجرام، واتساب) للدفع، أو تطلب تحويلاً مالياً مبكراً خارج التطبيق، أو تقدم وعوداً غير منطقية وSpam. قم بالرد بـ JSON يحتوي على: {"isSafe": true/false, "reason": "شرح مبسط وواضح للعميل باللغة العربية"}'
            },
            {'role': 'user', 'content': 'الطلب الأصلي: $requestText\n\nعرض الحرفي: $offerText'}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['choices'][0]['message']['content'] ?? '';
        final cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
      return {'isSafe': true, 'reason': 'تعذر التحليل المؤقت للشبكة.'};
    } catch (e) {
      return {'isSafe': true, 'reason': 'تعذر التحليل المؤقت.'};
    }
  }
}
