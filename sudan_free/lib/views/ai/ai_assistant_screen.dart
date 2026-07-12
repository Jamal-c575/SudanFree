import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_service.dart';
import '../../services/ai_search_tools.dart';
import '../../models/user_model.dart';
import '../../models/squad_model.dart';
import '../../models/request_model.dart';
import '../../models/post_model.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/common/linkable_text.dart';
import '../../core/utils/navigation_utils.dart';
import '../profile/profile_screen.dart';
import '../profile/squad_profile_screen.dart';
import '../requests/request_details_screen.dart';
import '../posts/post_details_screen.dart';
import '../profile/success_story_submission_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/common/premium_glass_card.dart';
import '../../widgets/common/premium_button.dart';
import 'package:sudan_free/utils/app_haptics.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<UserModel>? recommendedFreelancers;
  final List<SquadModel>? recommendedSquads;
  final List<RequestModel>? recommendedRequests;
  final List<PostModel>? recommendedPosts;
  final String? estimatedPriceRange;
  final Map<String, String>? aiExplanations;
  final List<String>? suggestedReplies;
  final List<String>? clarifyOptions;
  final Function(String)? onClarifySelected;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.recommendedFreelancers,
    this.recommendedSquads,
    this.recommendedRequests,
    this.recommendedPosts,
    this.estimatedPriceRange,
    this.aiExplanations,
    this.suggestedReplies,
    this.clarifyOptions,
    this.onClarifySelected,
  });
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final AiSearchTools _searchTools = AiSearchTools();

  static List<_ChatMessage>? _globalMessages;
  static DateTime? _lastClearTime;

  late List<_ChatMessage> _messages;

  bool _isLoading = false;
  String _loadingLabel = 'جاري التفكير...';

  @override
  void initState() {
    super.initState();
    _initMessages();
    _loadHistory();
    // تعيين بيانات المستخدم الحالي للذكاء الاصطناعي
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAiUser());
  }

  /// تمرير بيانات المستخدم المسجل للذكاء الاصطناعي
  void _initAiUser() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      _aiService.setCurrentUser(
        name: user.name,
        jobTitle: user.jobTitle ?? '',
        role: user.role.name,
      );
      // We only update the welcome message if the custom prompt hasn't been fetched yet
      // To do this safely, we will just call _fetchAiWelcomePrompt again so it applies the name
      _fetchAiWelcomePrompt();
    }
  }

  void _initMessages() {
    final now = DateTime.now();
    // Check if we need to clear (1:00 AM logic)
    if (_lastClearTime != null) {
      final chatDayNow = now.subtract(const Duration(hours: 1));
      final chatDayLast = _lastClearTime!.subtract(const Duration(hours: 1));
      if (chatDayNow.day != chatDayLast.day || chatDayNow.month != chatDayLast.month || chatDayNow.year != chatDayLast.year) {
        _globalMessages = null;
      }
    }
    
    if (_globalMessages == null) {
      _globalMessages = [
        _ChatMessage(
          text: 'مرحباً! أنا Home ✨\nكيف يمكنني مساعدتك اليوم؟\nيمكنني مساعدتك في البحث عن حرفيين، متاجر، فرص عمل، وكل ما يخص تطبيق سودان فري.',
          isUser: false,
        )
      ];
      _lastClearTime = now;
      _fetchAiWelcomePrompt();
    }
    _messages = _globalMessages!;
  }

  Future<void> _fetchAiWelcomePrompt() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('app_settings').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('ai_welcome_prompt') && data['ai_welcome_prompt'] != null && data['ai_welcome_prompt'].toString().isNotEmpty) {
           final prompt = data['ai_welcome_prompt'].toString();
           // Update message if it's the very first message
           if (mounted && _messages.isNotEmpty && !_messages[0].isUser) {
              final authProvider = context.read<AuthProvider>();
              final user = authProvider.user;
              String finalPrompt = prompt;
              if (user != null) {
                 final firstName = user.name.split(' ').first;
                 finalPrompt = 'مرحباً $firstName! 👋\n$prompt';
              }
              setState(() {
                 _messages[0] = _ChatMessage(text: finalPrompt, isUser: false);
                 _globalMessages![0] = _messages[0];
              });
           }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadHistory() async {
    // We already have memory persistence via _globalMessages.
    // If the list is larger than 1, we already loaded/have history.
    if (_messages.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
      return;
    }

    final history = await _aiService.loadSavedHistory();
    if (history.isNotEmpty && mounted) {
      setState(() {
        for (var msg in history) {
          List<UserModel>? rFreelancers;
          List<SquadModel>? rSquads;
          Map<String, String>? rExplanations;
          
          if (msg['cards'] != null && msg['cards'] is List) {
            final cardsList = msg['cards'] as List;
            for (var c in cardsList) {
               if (c is Map) {
                 if (c['type'] == 'freelancer') {
                    rFreelancers ??= [];
                    rFreelancers.add(UserModel.fromMap({
                       'id': c['id'] ?? '',
                       'name': c['name'] ?? '',
                       'jobTitle': c['jobTitle'],
                       'skills': c['skills'] != null && c['skills'].toString().isNotEmpty ? c['skills'].toString().split(', ') : [],
                       'createdAt': DateTime.now().toIso8601String(),
                       'updatedAt': DateTime.now().toIso8601String(),
                    }));
                 } else if (c['type'] == 'squad') {
                    rSquads ??= [];
                    rSquads.add(SquadModel(
                       id: c['id'] ?? '',
                       name: c['name'] ?? '',
                       description: c['description'] ?? '',
                       leaderId: '',
                       createdAt: DateTime.now(),
                       combinedSkills: c['skills'] != null && c['skills'].toString().isNotEmpty ? c['skills'].toString().split(', ') : [],
                    ));
                 }
               }
            }
          }
          
          if (msg['explanations'] != null && msg['explanations'] is Map) {
             rExplanations = Map<String, String>.from(msg['explanations'] as Map);
          }

          _messages.add(_ChatMessage(
            text: msg['content'] ?? '',
            isUser: msg['role'] == 'user',
            recommendedFreelancers: rFreelancers,
            recommendedSquads: rSquads,
            aiExplanations: rExplanations,
          ));
        }
      });
      // Scroll to bottom after loading history
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  // Regex to detect [TOOL: toolName | params]
  static final _toolRegex = RegExp(r'\[TOOL:\s*([^\|]+)\|([^\]]*)\]', caseSensitive: false);
  // Regex to detect [SUGGEST: ... ] for standard text responses
  static final _suggestRegex = RegExp(r'\[SUGGEST:(.*?)\]', caseSensitive: false);
  // Regex to detect [CLARIFY: question | option1 | option2 | option3 | option4]
  static final _clarifyRegex = RegExp(r'\[CLARIFY:\s*([^\|]+)\|(.+)\]', caseSensitive: false);

  void _sendMessage({String? predefinedText}) async {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _loadingLabel = 'جاري التفكير...';
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Step 1: Ask AI what it wants to do
      String aiResponse = await _aiService.sendMessage(text);
      
      // Check for CLARIFY response (ambiguous query needs user clarification)
      final clarifyMatch = _clarifyRegex.firstMatch(aiResponse);
      if (clarifyMatch != null) {
        final question = clarifyMatch.group(1)?.trim() ?? '';
        final optionsStr = clarifyMatch.group(2)?.trim() ?? '';
        final options = optionsStr.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        
        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(
              text: 'سؤال توضيحي: $question',
              isUser: false,
              clarifyOptions: options,
              onClarifySelected: (selectedOption) {
                _sendMessage(predefinedText: selectedOption);
              },
            ));
            _isLoading = false;
          });
          _scrollToBottom();
        }
        return;
      }
      
      final toolMatch = _toolRegex.firstMatch(aiResponse);
      final suggestMatch = _suggestRegex.firstMatch(aiResponse);
      
      List<String>? parsedSuggestions;
      if (suggestMatch != null) {
        parsedSuggestions = suggestMatch.group(1)?.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        aiResponse = aiResponse.replaceAll(_suggestRegex, '').trim();
      }

      String finalText = aiResponse;
      List<UserModel>? foundUsers;
      List<SquadModel>? foundSquads;
      List<RequestModel>? foundRequests;
      List<PostModel>? foundPosts;
      String? foundPriceRange;
      Map<String, String>? explanations;

      if (toolMatch != null) {
        final toolName = toolMatch.group(1)?.trim() ?? '';
        final params = toolMatch.group(2)?.trim() ?? '';

        // Step 2: Show search indicator & execute real Firestore query
        if (mounted) setState(() => _loadingLabel = '🔍 جاري البحث في التطبيق...');

        final auth = context.read<AuthProvider>();
        final lat = auth.user?.latitude;
        final lng = auth.user?.longitude;

        final toolResult = await _searchTools.executeToolCall(toolName, params, lat: lat, lng: lng);
        foundUsers = toolResult.users.isNotEmpty ? toolResult.users : null;
        foundSquads = toolResult.squads.isNotEmpty ? toolResult.squads : null;
        foundRequests = toolResult.requests.isNotEmpty ? toolResult.requests : null;
        foundPosts = toolResult.posts.isNotEmpty ? toolResult.posts : null;
        foundPriceRange = toolResult.estimatedPriceRange;

        if (toolResult.hasResults) {
          // ─── CONVERSATION STATE UPDATE ───
          _aiService.updateConversationState('lastTool', toolName);
          
          List<Map<String, String>> shortResults = [];
          
          if (foundUsers != null && foundUsers.isNotEmpty) {
            if (foundUsers.length == 1) {
              _aiService.updateConversationState('activeEntity', foundUsers.first.id);
              _aiService.updateConversationState('entityId', foundUsers.first.id);
              _aiService.updateConversationState('entityType', 'freelancer');
              _aiService.updateConversationState('entityName', foundUsers.first.name);
            }
            shortResults = foundUsers.take(3).map<Map<String, String>>((u) => {
              'id': u.id, 
              'name': u.name,
              'jobTitle': u.jobTitle ?? '',
              'skills': u.skills?.join(', ') ?? '',
              'type': 'freelancer'
            }).toList();
          } else if (foundSquads != null && foundSquads.isNotEmpty) {
            if (foundSquads.length == 1) {
              _aiService.updateConversationState('activeEntity', foundSquads.first.id);
              _aiService.updateConversationState('entityId', foundSquads.first.id);
              _aiService.updateConversationState('entityType', 'squad');
              _aiService.updateConversationState('entityName', foundSquads.first.name);
            }
            shortResults = foundSquads.take(3).map<Map<String, String>>((s) => {
              'id': s.id, 
              'name': s.name,
              'description': s.description ?? '',
              'skills': s.combinedSkills.join(', '),
              'type': 'squad'
            }).toList();
          } else if (foundRequests != null && foundRequests.isNotEmpty) {
            if (foundRequests.length == 1) {
              _aiService.updateConversationState('activeEntity', foundRequests.first.id);
              _aiService.updateConversationState('entityId', foundRequests.first.id);
              _aiService.updateConversationState('entityType', 'request');
              _aiService.updateConversationState('entityName', foundRequests.first.text);
            }
            shortResults = foundRequests.take(3).map<Map<String, String>>((r) => {'id': r.id, 'name': r.text, 'type': 'request'}).toList();
          } else if (foundPosts != null && foundPosts.isNotEmpty) {
            if (foundPosts.length == 1) {
              _aiService.updateConversationState('activeEntity', foundPosts.first.id);
              _aiService.updateConversationState('entityId', foundPosts.first.id);
              _aiService.updateConversationState('entityType', 'post');
              _aiService.updateConversationState('entityName', foundPosts.first.caption ?? "منشور");
            }
            shortResults = foundPosts.take(3).map<Map<String, String>>((p) => {'id': p.id, 'name': p.caption ?? "منشور", 'type': 'post'}).toList();
          }

          final structuredSearch = {
            'tool': toolName,
            'query': params,
            'results': shortResults,
          };
          
          _aiService.updateConversationState('activeSearch', structuredSearch);
          _aiService.updateConversationState('lastResults', shortResults);
          _aiService.updateConversationState('lastTool', toolName);
          // ──────────────────────────────────

          // Step 3: Feed real data back to AI for structured JSON output
          if (mounted) setState(() => _loadingLabel = '✍️ جاري صياغة النتائج...');
          final contextMsg =
              'البيانات الحقيقية:\n${toolResult.context}\n\n'
              'المطلوب: قم بالرد بتنسيق JSON حصراً يحتوي على:\n'
              '1. "intro": جملة واحدة قصيرة جداً لتقديم النتائج.\n'
              '2. "items": مصفوفة كائنات، كل كائن له "id" و "ai_explanation" (شرح جذاب من سطرين يبرز ميزات هذا العنصر).\n'
              '3. "suggested_replies": مصفوفة نصوص لأسئلة استباقية يمكن للمستخدم الضغط عليها لمعرفة المزيد (مثل: "كيف أتواصل معه؟"، "هل هناك خيارات أرخص؟").\n'
              'الرد يجب أن يكون JSON فقط.';
              
          final jsonStr = await _aiService.sendContextMessageJson(contextMsg);
          try {
            final decoded = jsonDecode(jsonStr);
            finalText = AiService.sanitize(decoded['intro']?.toString() ?? 'النتائج كالتالي:');
            
            if (decoded['suggested_replies'] != null) {
               parsedSuggestions = List<String>.from(decoded['suggested_replies']);
            }
            
            if (decoded['items'] != null) {
               explanations = {};
               for (var item in decoded['items']) {
                 if (item['id'] != null && item['ai_explanation'] != null) {
                   explanations[item['id'].toString()] = AiService.sanitize(item['ai_explanation'].toString());
                 }
               }
            }
          } catch (e) {
            finalText = 'إليك النتائج التي وجدتها لك:';
          }
        } else {
          finalText = AiService.sanitize(toolResult.context);
        }
      }

      // Save the structured data to history so it re-renders cards
      _aiService.appendAssistantMessage(
        finalText.trim(),
        cards: _aiService.conversationState['activeSearch']?['results'] as List<Map<String, String>>?,
        explanations: explanations,
      );

      setState(() {
        _messages.add(_ChatMessage(
          text: finalText,
          isUser: false,
          recommendedFreelancers: foundUsers,
          recommendedSquads: foundSquads,
          recommendedRequests: foundRequests,
          recommendedPosts: foundPosts,
          estimatedPriceRange: foundPriceRange,
          aiExplanations: explanations,
          suggestedReplies: parsedSuggestions,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'عذراً، حدث خطأ في الاتصال. الرجاء المحاولة مجدداً.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.handshake, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _loadingLabel,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              _buildMessageInput(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedReplies(List<String> replies, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: replies.map((reply) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                _sendMessage(predefinedText: reply);
              },
              borderRadius: BorderRadius.circular(20),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: BorderRadius.circular(20),
                color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200),
                child: Text(
                  reply,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClarifyOptions(List<String> options, Function(String)? onSelected, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 6,
      children: options.map((option) {
        return InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            if (onSelected != null) onSelected(option);
          },
          borderRadius: BorderRadius.circular(12),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            borderRadius: BorderRadius.circular(12),
            color: isDark ? Colors.amber.withValues(alpha: 0.15) : Colors.amber.shade50,
            border: Border.all(
              color: isDark ? Colors.amber.withValues(alpha: 0.4) : Colors.amber.shade200,
              width: 1.5,
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, bool isDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (message.text.isNotEmpty)
              GlassContainer(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomRight: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
                color: message.isUser
                    ? Theme.of(context).primaryColor.withValues(alpha: isDark ? 0.4 : 0.8)
                    : (isDark ? Colors.white12 : Colors.white),
                border: Border.all(
                  color: message.isUser
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.5)
                      : (isDark ? Colors.white24 : Colors.black12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LinkableText(
                  text: message.text.replaceAll('#success_story', ''),
                  style: TextStyle(
                    color: message.isUser
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black87),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            if (!message.isUser && message.text.contains('#success_story')) ...[
              const SizedBox(height: 12),
              PremiumButton(
                onPressed: () {
                  AppHaptics.lightImpact();
                  Navigator.push(
                    context,
                    AnimationUtils.createPremiumRoute(const SuccessStorySubmissionScreen()),
                  );
                },
                icon: Icons.emoji_events,
                label: 'شارك قصة نجاحك الآن',
                isPrimary: false,
              ),
            ],
            if (message.recommendedFreelancers != null) ...[
              const SizedBox(height: 8),
              _buildRecommendationList(message.recommendedFreelancers!, message.aiExplanations, isDark),
            ],
            if (message.recommendedSquads != null) ...[
              const SizedBox(height: 8),
              _buildSquadList(message.recommendedSquads!, message.aiExplanations, isDark),
            ],
            if (message.recommendedRequests != null) ...[
              const SizedBox(height: 8),
              _buildRequestList(message.recommendedRequests!, message.aiExplanations, isDark),
            ],
            if (message.recommendedPosts != null) ...[
              const SizedBox(height: 8),
              _buildPostList(message.recommendedPosts!, message.aiExplanations, isDark),
            ],
            if (message.estimatedPriceRange != null) ...[
              const SizedBox(height: 8),
              _buildPriceEstimationBox(message.estimatedPriceRange!, isDark),
            ],
            if (message.suggestedReplies != null && message.suggestedReplies!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildSuggestedReplies(message.suggestedReplies!, isDark),
            ],
            if (message.clarifyOptions != null && message.clarifyOptions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildClarifyOptions(message.clarifyOptions!, message.onClarifySelected, isDark),
            ],
          ],
        ),
      ),
    ).animate().fade(duration: const Duration(milliseconds: 300)).slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300));
  }

  Widget _buildSquadList(List<SquadModel> squads, Map<String, String>? aiExplanations, bool isDark) {
    return _ExpandableListWrapper(
      isDark: isDark,
      itemCount: squads.length,
      itemBuilder: (context, index) {
        final squad = squads[index];
        final aiExplanation = aiExplanations?[squad.id];

        return PremiumGlassCard(
          onTap: () {
            AppHaptics.lightImpact();
            _aiService.updateConversationState('activeEntity', squad.id);
            _aiService.updateConversationState('entityId', squad.id);
            _aiService.updateConversationState('entityType', 'squad');
            _aiService.updateConversationState('entityName', squad.name);
            _aiService.updateConversationState('lastViewedEntity', squad.id);
            NavigationUtils.navigateSafely(
              context,
              SquadProfileScreen(squad: squad),
            );
          },
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.white : Colors.white,
          opacity: isDark ? 0.05 : 0.8,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.amber.withValues(alpha: 0.2),
                    child: Icon(Icons.groups, color: isDark ? Colors.amber.shade200 : Colors.amber, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          squad.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          squad.category.getName("ar"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${squad.rating.toStringAsFixed(1)} | ${squad.memberIds.length} أعضاء',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                squad.state ?? 'موقع غير محدد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (aiExplanation != null && aiExplanation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiExplanation,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestList(List<RequestModel> requests, Map<String, String>? aiExplanations, bool isDark) {
    return _ExpandableListWrapper(
      isDark: isDark,
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final aiExplanation = aiExplanations?[req.id];
        
        // Calculate remaining time
        String timeRemaining = "مفتوح";
        final now = DateTime.now();
        final difference = req.expiresAt.difference(now);
        if (difference.isNegative) {
          timeRemaining = "منتهي";
        } else if (difference.inDays > 0) {
          timeRemaining = "باقي ${difference.inDays} يوم";
        } else if (difference.inHours > 0) {
          timeRemaining = "باقي ${difference.inHours} ساعة";
        } else {
          timeRemaining = "باقي ${difference.inMinutes} دقيقة";
        }
      
        return PremiumGlassCard(
          onTap: () {
            AppHaptics.lightImpact();
            _aiService.updateConversationState('activeEntity', req.id);
            _aiService.updateConversationState('entityId', req.id);
            _aiService.updateConversationState('entityType', 'request');
            _aiService.updateConversationState('entityName', req.text);
            _aiService.updateConversationState('lastViewedEntity', req.id);
            NavigationUtils.navigateSafely(
              context,
              RequestDetailsScreen(request: req),
            );
          },
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.white : Colors.white,
          opacity: isDark ? 0.05 : 0.8,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                req.category ?? 'طلب خدمة',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (timeRemaining == "منتهي") ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                timeRemaining,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (timeRemaining == "منتهي") ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              req.price != null ? '${req.price} ج' : 'غير محدد',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${req.offersCount} عروض',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: PremiumButton(
                            onPressed: () {
                              AppHaptics.lightImpact();
                              NavigationUtils.navigateSafely(
                                context,
                                RequestDetailsScreen(request: req),
                              );
                            },
                            icon: Icons.local_offer,
                            label: 'قدّم عرضك الآن',
                            isPrimary: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (aiExplanation != null && aiExplanation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiExplanation,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostList(List<PostModel> posts, Map<String, String>? aiExplanations, bool isDark) {
    return _ExpandableListWrapper(
      isDark: isDark,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final aiExplanation = aiExplanations?[post.id];

        return PremiumGlassCard(
          onTap: () {
            AppHaptics.lightImpact();
            _aiService.updateConversationState('activeEntity', post.id);
            _aiService.updateConversationState('entityId', post.id);
            _aiService.updateConversationState('entityType', 'post');
            _aiService.updateConversationState('entityName', post.caption ?? "منشور");
            _aiService.updateConversationState('lastViewedEntity', post.id);
            NavigationUtils.navigateSafely(
              context,
              PostDetailsScreen(post: post),
            );
          },
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.white : Colors.white,
          opacity: isDark ? 0.05 : 0.8,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      image: (post.imageUrls.isNotEmpty || post.imageUrl != null)
                          ? DecorationImage(
                              image: NetworkImage(
                                post.imageUrls.isNotEmpty ? post.imageUrls.first : post.imageUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (post.imageUrls.isEmpty && post.imageUrl == null)
                        ? Icon(Icons.shopping_bag, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.caption ?? 'منتج بدون اسم',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (post.category != null)
                          Text(
                            post.category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              post.price != null ? '${post.price} ج' : 'تواصل لمعرفة السعر',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.person, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  post.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (aiExplanation != null && aiExplanation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiExplanation,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationList(List<UserModel> freelancers, Map<String, String>? aiExplanations, bool isDark) {
    return _ExpandableListWrapper(
      isDark: isDark,
      itemCount: freelancers.length,
      itemBuilder: (context, index) {
        final freelancer = freelancers[index];
        final aiExplanation = aiExplanations?[freelancer.id];

        return PremiumGlassCard(
          onTap: () {
            AppHaptics.lightImpact();
            _aiService.updateConversationState('activeEntity', freelancer.id);
            _aiService.updateConversationState('entityId', freelancer.id);
            _aiService.updateConversationState('entityType', 'freelancer');
            _aiService.updateConversationState('entityName', freelancer.name);
            _aiService.updateConversationState('lastViewedEntity', freelancer.id);
            NavigationUtils.navigateSafely(
              context,
              ProfileScreen(userId: freelancer.id),
            );
          },
          padding: const EdgeInsets.all(16),
          color: isDark ? Colors.white : Colors.white,
          opacity: isDark ? 0.05 : 0.8,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: (freelancer.profileImageUrl != null && freelancer.profileImageUrl!.isNotEmpty)
                        ? NetworkImage(freelancer.profileImageUrl!)
                        : null,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: (freelancer.profileImageUrl == null || freelancer.profileImageUrl!.isEmpty)
                        ? Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 36)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                freelancer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (freelancer.isVerified)
                              const Icon(Icons.handshake_rounded, color: Colors.blue, size: 18),
                          ],
                        ),
                        if (freelancer.jobTitle != null && freelancer.jobTitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            freelancer.jobTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${freelancer.rating.toStringAsFixed(1)} | ${freelancer.reviewsCount} تقييم',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.location_on, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                freelancer.state ?? 'موقع غير محدد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (aiExplanation != null && aiExplanation.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: isDark ? Colors.blue.shade300 : Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          aiExplanation,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceEstimationBox(String priceRange, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      enableBlur: true,
      blur: 12,
      opacity: isDark ? 0.15 : 0.4,
      color: isDark ? Colors.teal.shade900 : Colors.teal.shade50,
      border: Border.all(
        color: Colors.teal.withValues(alpha: 0.5),
        width: 1.5,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.price_check, color: Colors.teal.shade300, size: 24),
              const SizedBox(width: 8),
              Text(
                'تسعير الخدمة التقريبي',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.teal.shade100 : Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            priceRange,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هذا السعر تقريبي بناءً على الطلبات المشابهة في التطبيق',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _isRecording = false;
  AudioRecorder? _audioRecorder;
  String? _recordingPath;

  Future<void> _startVoiceInput() async {
    try {
      _audioRecorder = AudioRecorder();
      if (await _audioRecorder!.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordingPath = '${dir.path}/ai_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder!.start(const RecordConfig(), path: _recordingPath!);
        setState(() {
          _isRecording = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يرجى السماح بالوصول إلى الميكروفون')),
          );
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      debugPrint('Voice recording error: $e');
    }
  }

  Future<void> _cancelVoiceInput() async {
    if (_audioRecorder != null) {
      await _audioRecorder!.stop();
      await _audioRecorder!.dispose();
      _audioRecorder = null;
    }
    setState(() {
      _isRecording = false;
      _recordingPath = null;
    });
  }

  Future<void> _stopAndSendVoiceInput() async {
    if (_audioRecorder == null) return;
    
    try {
      final recordPath = await _audioRecorder!.stop();
      await _audioRecorder!.dispose();
      _audioRecorder = null;
      
      setState(() {
        _isRecording = false;
      });

      if (recordPath != null) {
        setState(() {
          _isLoading = true;
          _loadingLabel = '🎙️ جاري تحويل الصوت...';
        });
        final transcribed = await _aiService.transcribeAudioToServiceRequest(recordPath);
        setState(() => _isLoading = false);
        if (transcribed.isNotEmpty && !transcribed.startsWith('لم أتمكن') && !transcribed.startsWith('حدث خطأ')) {
          _controller.text = transcribed;
          _sendMessage();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(transcribed), backgroundColor: Colors.red.shade400),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      debugPrint('Voice sending error: $e');
    }
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _isRecording ? _buildRecordingUi(isDark) : _buildNormalInputUi(isDark),
    );
  }

  Widget _buildRecordingUi(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: _cancelVoiceInput,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.delete_outline, color: Colors.grey.shade600, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 500.ms).fadeOut(duration: 500.ms),
                const SizedBox(width: 12),
                Text(
                  'جاري التسجيل...',
                  style: TextStyle(
                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _stopAndSendVoiceInput,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalInputUi(bool isDark) {
    return Row(
      children: [
        // Voice input button
        GestureDetector(
          onTap: _isLoading ? null : _startVoiceInput,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.mic,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Colors.black26 : Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _isLoading ? null : _sendMessage,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _ExpandableListWrapper extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool isDark;

  const _ExpandableListWrapper({
    required this.itemCount,
    required this.itemBuilder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
          iconColor: isDark ? Colors.white : Colors.black,
          title: Text(
            'مُقترح خصيصاً لك ($itemCount)',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          leading: const Icon(
            Icons.auto_awesome,
            color: Colors.amber,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: itemBuilder,
            ),
          ],
        ),
      ),
    );
  }
}
