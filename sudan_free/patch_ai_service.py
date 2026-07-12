import re

with open('/tmp/ai_service_backup.dart', 'r') as f:
    content = f.read()

# Replace imports
if "import 'package:cloud_functions/cloud_functions.dart';" not in content:
    content = content.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'package:cloud_functions/cloud_functions.dart';")

# Add conversation state map and logic
state_vars = """
  // ═══ بيانات المستخدم الحالي ═══
  String _currentUserName    = '';
  String _currentUserJobTitle = '';
  String _currentUserRole    = '';

  // ═══ حالة المحادثة الحالية (Conversation State) ═══
  final Map<String, dynamic> _conversationState = {
    'currentIntent': null,
    'previousIntent': null,
    'activeEntity': null,
    'activeCategory': null,
    'activeSearch': null,
    'lastTool': null,
    'lastFilters': null,
  };

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
"""

content = re.sub(r'  SharedPreferences\? _prefs;\n\n  AiService._internal\(\) \{', 
                 r'  SharedPreferences? _prefs;\n' + state_vars + r'\n  AiService._internal() {', content)


# Rewrite sendMessage
sendMessage_new = """
  Future<String> sendMessage(String text) async {
    if (_isRateLimited()) {
      return 'عذراً، تجاوزت الحد (5 رسائل/دقيقة). انتظر شوية. 🛡️';
    }

    _chatHistory.add({'role': 'user', 'content': text});
    _saveHistory();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('ai_chatWithHome');
      final result = await callable.call({
        'messages': _chatHistory,
        'userContext': _userContext,
        'useTools': true,
      });

      final data = result.data as Map<String, dynamic>;
      
      // ─── CLARIFY ───
      if (data['type'] == 'clarify') {
        final question = data['question'] as String? ?? '';
        final options = List<String>.from(data['options'] as List? ?? []);
        final intro = data['intro'] as String? ?? '';
        
        _chatHistory.add({'role': 'assistant', 'content': '[CLARIFY]\\n$intro'});
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
          _conversationState['previousIntent'] = _conversationState['currentIntent'];
          _conversationState['currentIntent'] = arguments['intent'];
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
      if (e.toString().contains('SocketException')) {
        return 'عذراً، مشكلة في الاتصال. تأكد من الإنترنت.';
      }
      return 'عذراً، حدث خطأ. حاول مجدداً.';
    }
  }

  Future<String> sendContextMessageJson(String contextData) async {
    final messagesWithContext = [
      ..._chatHistory,
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
        final structuredMemory = {
          "SYSTEM_MEMORY": {
            "type": "search_results",
            "data": _conversationState['activeSearch']
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
      if (e.toString().contains('SocketException')) {
        return 'عذراً، مشكلة في الاتصال. تأكد من الإنترنت.';
      }
      return 'عذراً، حدث خطأ. حاول مجدداً.';
    }
  }
"""

content = re.sub(r'  Future<String> sendMessage\(String text\) async \{[\s\S]*?    return response;\n  }', 
                 sendMessage_new + r'\n\n  String _filterResponse(String response) {\n    final lower = response.toLowerCase();\n    final offTopicKeywords = [\'برمجة\', \'كود\', \'html\', \'css\', \'javascript\', \'python\', \'اكتب لي كود\', \'قواعد بيانات\'];\n    for (final keyword in offTopicKeywords) {\n      if (lower.contains(keyword)) {\n        return \'هذا خارج نطاق عملي.\\nهل تحتاج مساعدة في البحث عن خدمة ما؟\';\n      }\n    }\n    return response;\n  }', content)

with open('lib/services/ai_service.dart', 'w') as f:
    f.write(content)

print("Patched lib/services/ai_service.dart")
