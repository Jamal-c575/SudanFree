import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;

  String get _baseUrl {
    try {
      final url = FirebaseRemoteConfig.instance.getString('ai_base_url');
      if (url.isNotEmpty) return url;
    } catch (_) {}
    return 'https://api.groq.com/openai/v1/chat/completions';
  }

  String get _audioUrl {
    try {
      final url = FirebaseRemoteConfig.instance.getString('ai_audio_url');
      if (url.isNotEmpty) return url;
    } catch (_) {}
    return 'https://api.groq.com/openai/v1/audio/transcriptions';
  }

  String get _model {
    try {
      final model = FirebaseRemoteConfig.instance.getString('ai_model');
      if (model.isNotEmpty) return model;
    } catch (_) {}
    return 'llama-3.3-70b-versatile';
  }

  late String _fallbackApiKey;

  String get _apiKey {
    try {
      final key = FirebaseRemoteConfig.instance.getString('ai_api_key');
      if (key.isNotEmpty) return key;
    } catch (_) {}
    return _fallbackApiKey;
  }
  
  final List<Map<String, dynamic>> _chatHistory = [];
  
  // Rate Limiting
  final List<DateTime> _messageTimestamps = [];
  static const int _maxMessagesPerMinute = 5;

  SharedPreferences? _prefs;

  // ═══ بيانات المستخدم الحالي ═══
  String _currentUserName    = '';
  String _currentUserJobTitle = '';
  String _currentUserRole    = '';

  // ═══ حالة المحادثة الحالية (Conversation State) ═══
  final Map<String, dynamic> _conversationState = {
    'currentIntent': null,
    'lastIntent': null,
    'previousIntent': null,
    'lastTool': null,
    'activeEntity': null, 
    'entityId': null,
    'entityType': null,
    'entityName': null,
    'lastViewedEntity': null,
    'selectedResult': null,
    'summary': null,
    'conversationSummary': null,
    'conversationGoal': null,
    'activeSearch': null,
    'lastResults': null,
    'lastFilters': null,
    'currentCategory': null,
    'currentCollection': null,
  };

  void setCurrentUser({required String name, required String jobTitle, required String role}) {
    _currentUserName = name;
    _currentUserJobTitle = jobTitle;
    _currentUserRole = role;
  }

  static String sanitize(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  void updateConversationState(String key, dynamic value) {
    _conversationState[key] = value;
  }

  Map<String, dynamic> get conversationState => _conversationState;

  Map<String, dynamic> get _userContext => {
    'name':     _currentUserName,
    'jobTitle': _currentUserJobTitle,
    'role':     _currentUserRole,
    'conversationState': _conversationState,
  };

  AiService._internal() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _fallbackApiKey = '';
      print('WARNING: GROQ_API_KEY is missing from .env file.');
    } else {
      _fallbackApiKey = apiKey;
    }
    
    // Default synchronous init so history is never totally null.
    // Real load happens via loadSavedHistory()
    _initHistory();
    
    // Asynchronously fetch remote config to keep it updated for future calls
    _initRemoteConfig();
  }

  Future<void> _initRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults(const {
        'ai_base_url': '',
        'ai_audio_url': '',
        'ai_model': '',
        'ai_api_key': '',
      });
      await remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Failed to initialize Remote Config: $e');
    }
  }

  void _initHistory() {
    _chatHistory.clear();
    _chatHistory.add({'role': 'system', 'content': 'Init'});
  }

  void clearHistory() {
    _chatHistory.clear();
    _chatHistory.add({'role': 'system', 'content': 'Init'});
    _saveHistory();
  }

  Future<void> _saveHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('ai_chat_last_date', DateTime.now().toIso8601String());
    await _prefs!.setString('ai_chat_history', jsonEncode(_chatHistory));
  }

  /// Loads history from shared preferences, checking if it's the same day.
  /// Returns only the 'user' and 'assistant' messages for UI building.
  Future<List<Map<String, dynamic>>> loadSavedHistory() async {
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
            _chatHistory.add(Map<String, dynamic>.from(item));
          }
        } catch (_) {
          clearHistory();
          return [];
        }
      }
      
      return _chatHistory.where((msg) {
        if (msg['role'] != 'user' && msg['role'] != 'assistant') return false;
        if ((msg['content'] ?? '').contains('SYSTEM_MEMORY')) return false;
        return true;
      }).toList();
    }
  }

  Map<String, String> _buildSystemPrompt() => {
    'role': 'system',
    'content': 'Init'
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
      return 'عذراً، تجاوزت الحد (5 رسائل/دقيقة). انتظر شوية. 🛡️';
    }

    _chatHistory.add({'role': 'user', 'content': text});
    _saveHistory();

    try {
      final cleanHistory = _chatHistory.map((e) => {
        'role': e['role'],
        'content': e['content']
      }).toList();

      final callable = FirebaseFunctions.instance.httpsCallable('ai_chatWithHome');
      final result = await callable.call({
        'messages': cleanHistory,
        'userContext': _userContext,
        'useTools': true,
      });

      final data = result.data as Map<String, dynamic>;
      
      // ─── CLARIFY ───
      if (data['type'] == 'clarify') {
        final question = data['question'] as String? ?? '';
        final options = List<String>.from(data['options'] as List? ?? []);
        final intro = data['intro'] as String? ?? '';
        
        _chatHistory.add({'role': 'assistant', 'content': '[CLARIFY]\n$intro'});
        _saveHistory();
        return '[CLARIFY: $question | ${options.join(" | ")}]';
      }
      
      // ─── TOOL_CALL ───
      if (data['type'] == 'tool_call') {
        final toolName = data['toolName'] as String? ?? '';
        final arguments = data['arguments'] as Map? ?? {};
        
        String argValue = '';
        if (arguments.containsKey('query')) {
          argValue = arguments['query'].toString();
        } else if (arguments.containsKey('category')) {
          argValue = arguments['category'].toString();
        }

        if (arguments.containsKey('intent')) {
          String newIntent = arguments['intent'].toString();
          String oldIntent = _conversationState['currentIntent']?.toString() ?? '';
          
          if (oldIntent.isNotEmpty && oldIntent != newIntent) {
            // Rule 8 & 17: Change of topic
            _conversationState['previousIntent'] = oldIntent;
            _conversationState['activeEntity'] = null; // Reset entity when topic changes
            _conversationState['entityId'] = null;
            _conversationState['entityType'] = null;
            _conversationState['entityName'] = null;
            _conversationState['selectedResult'] = null;
            _conversationState['summary'] = null;
          }
          _conversationState['currentIntent'] = newIntent;
        }
        
        return '[TOOL: $toolName | $argValue]';
      }
      
      // ─── TEXT ───
      final responseText = data['content'] as String? ?? '';
      final filtered = _filterResponse(responseText);
      
      _chatHistory.add({'role': 'assistant', 'content': filtered});
      _saveHistory();
      return filtered;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        return e.message ?? 'عذراً، حدث خطأ. حاول مجدداً.';
      }
      if (e.toString().contains('SocketException')) {
        return 'عذراً، مشكلة في الاتصال. تأكد من الإنترنت.';
      }
      return 'عذراً، حدث خطأ. حاول مجدداً.';
    }
  }

  void appendAssistantMessage(String text, {List<Map<String, String>>? cards, Map<String, String>? explanations}) {
    final msg = <String, dynamic>{'role': 'assistant', 'content': text};
    if (cards != null) msg['cards'] = cards;
    if (explanations != null) msg['explanations'] = explanations;
    _chatHistory.add(msg);
    _saveHistory();
  }

  Future<String> sendContextMessageJson(String contextData) async {
    final messagesWithContext = [
      ..._chatHistory.map((e) => {
        'role': e['role'],
        'content': e['content']
      }),
      {'role': 'user', 'content': contextData},
    ];

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('ai_chatWithHome');
      final result = await callable.call({
        'messages': messagesWithContext,
        'userContext': _userContext,
        'forceJson': true,
      });

      final data = result.data;
      
      if (_conversationState['activeSearch'] != null) {
        // Compress data to reduce token usage
        Map<String, dynamic> compressedData = {};
        if (_conversationState['activeSearch'] is List) {
           final items = _conversationState['activeSearch'] as List;
           compressedData['count'] = items.length;
           compressedData['top_items'] = items.take(3).map((e) {
             if (e is Map) {
               return {
                 'id': e['id'],
                 'name': e['name'] ?? e['title'],
                 'jobTitle': e['jobTitle'] ?? e['category'],
               };
             }
             return e;
           }).toList();
        } else {
           compressedData = _conversationState['activeSearch'];
        }

        final structuredMemory = {
          "SYSTEM_MEMORY": {
            "type": "search_results",
            "summary": "This is a compressed summary. Do NOT search again for this.",
            "data": compressedData
          }
        };
        _chatHistory.add({
          'role': 'assistant',
          'content': jsonEncode(structuredMemory)
        });
        _saveHistory();
      }

      return data['content'] as String;
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        return e.message ?? 'عذراً، حدث خطأ. حاول مجدداً.';
      }
      if (e.toString().contains('SocketException')) {
        return 'عذراً، مشكلة في الاتصال. تأكد من الإنترنت.';
      }
      return 'عذراً، حدث خطأ. حاول مجدداً.';
    }
  }


  String _filterResponse(String response) {
    String filtered = response;
    
    // Hide tool schemas hallucinated by the model
    if (filtered.contains('<function/>') || filtered.contains("{'name':") || filtered.contains('{"name":') || filtered.contains('searchFreelancers')) {
      int index = filtered.indexOf('{');
      if (index > 0) {
        String safeText = filtered.substring(0, index).trim();
        if (safeText.isNotEmpty) {
           filtered = safeText;
        } else {
           filtered = 'عذراً، أواجه مشكلة تقنية حالياً في معالجة طلبك.';
        }
      } else if (filtered.contains('<function/>')) {
        filtered = filtered.replaceAll('<function/>', '').trim();
      }
    }

    final lower = filtered.toLowerCase();
    final offTopicKeywords = ['برمجة', 'كود', 'html', 'css', 'javascript', 'python', 'اكتب لي كود', 'قواعد بيانات'];
    for (final keyword in offTopicKeywords) {
      if (lower.contains(keyword)) {
        return 'هذا خارج نطاق عملي.\nهل تحتاج مساعدة في البحث عن خدمة ما؟';
      }
    }
    return filtered;
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
          'response_format': {"type": "json_object"},
          'messages': [
            {
              'role': 'system',
              'content': 'الرجاء إعادة صياغة النص التالي ليكون احترافياً، واضحاً ومصاغاً بلغة سليمة ومناسبة لطلبات العمل. قم بتصحيح الأخطاء الإملائية واللغوية. قم بالرد بـ JSON حصراً بالشكل التالي: {"enhanced_text": "النص المحسن هنا"}'
            },
            {'role': 'user', 'content': originalText}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final textResponse = data['choices'][0]['message']['content'] ?? '';
        final cleanJson = textResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> parsed = jsonDecode(cleanJson);
        return parsed['enhanced_text']?.toString().trim() ?? originalText;
      }
      return originalText;
    } catch (e) {
      return originalText;
    }
  }

  Future<String> enhanceProductDescription(String originalText) async {
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
          'response_format': {"type": "json_object"},
          'messages': [
            {
              'role': 'system',
              'content': 'أنت مسوق إلكتروني محترف ومبدع. الرجاء إعادة كتابة الوصف التالي للمنتج ليكون جذاباً جداً، تسويقياً، ويشجع الزبون على الشراء فوراً. استخدم الإيموجيز المناسبة، ورتب النص بشكل مريح للعين (نقاط، مميزات). قم بالرد بـ JSON حصراً بالشكل التالي: {"enhanced_text": "النص التسويقي هنا"}'
            },
            {'role': 'user', 'content': originalText}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final content = decoded['choices'][0]['message']['content'];
        final jsonContent = jsonDecode(content);
        return jsonContent['enhanced_text'] ?? originalText;
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
        return transcribedText;
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
