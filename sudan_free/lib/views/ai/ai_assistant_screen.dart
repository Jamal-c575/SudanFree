import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../profile/success_story_submission_screen.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/common/premium_glass_card.dart';
import '../../widgets/common/premium_button.dart';

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

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.recommendedFreelancers,
    this.recommendedSquads,
    this.recommendedRequests,
    this.recommendedPosts,
    this.estimatedPriceRange,
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
    }
    _messages = _globalMessages!;
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
          _messages.add(_ChatMessage(
            text: msg['content'] ?? '',
            isUser: msg['role'] == 'user',
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

  void _sendMessage() async {
    final text = _controller.text.trim();
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
      final aiResponse = await _aiService.sendMessage(text);
      final toolMatch = _toolRegex.firstMatch(aiResponse);

      String finalText = aiResponse;
      List<UserModel>? foundUsers;
      List<SquadModel>? foundSquads;
      List<RequestModel>? foundRequests;
      List<PostModel>? foundPosts;
      String? foundPriceRange;

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
          // Step 3: Feed real data back to AI for a polished summary
          if (mounted) setState(() => _loadingLabel = '✍️ جاري صياغة النتائج...');
          final contextMsg =
              'هذه هي البيانات الحقيقية من قاعدة بيانات التطبيق. '
              'قدّمها للمستخدم بشكل منظم وجذاب مع التقييم والحالة والموقع:\n\n'
              '${toolResult.context}';
          finalText = await _aiService.sendContextMessage(contextMsg);
        } else {
          finalText = toolResult.context;
        }
      }

      setState(() {
        _messages.add(_ChatMessage(
          text: finalText,
          isUser: false,
          recommendedFreelancers: foundUsers,
          recommendedSquads: foundSquads,
          recommendedRequests: foundRequests,
          recommendedPosts: foundPosts,
          estimatedPriceRange: foundPriceRange,
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
                    ? Theme.of(context).primaryColor.withOpacity(isDark ? 0.4 : 0.8)
                    : (isDark ? Colors.white12 : Colors.white),
                border: Border.all(
                  color: message.isUser
                      ? Theme.of(context).primaryColor.withOpacity(0.5)
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
                  HapticFeedback.lightImpact();
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
              _buildRecommendationList(message.recommendedFreelancers!, isDark),
            ],
            if (message.recommendedSquads != null) ...[
              const SizedBox(height: 8),
              _buildSquadList(message.recommendedSquads!, isDark),
            ],
            if (message.recommendedRequests != null) ...[
              const SizedBox(height: 8),
              _buildRequestList(message.recommendedRequests!, isDark),
            ],
            if (message.recommendedPosts != null) ...[
              const SizedBox(height: 8),
              _buildPostList(message.recommendedPosts!, isDark),
            ],
            if (message.estimatedPriceRange != null) ...[
              const SizedBox(height: 8),
              _buildPriceEstimationBox(message.estimatedPriceRange!, isDark),
            ],
          ],
        ),
      ),
    ).animate().fade(duration: const Duration(milliseconds: 300)).slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300));
  }

  Widget _buildSquadList(List<SquadModel> squads, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: squads.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final squad = squads[index];
          return PremiumGlassCard(
            onTap: () {
              HapticFeedback.lightImpact();
              NavigationUtils.navigateSafely(
                context,
                SquadProfileScreen(squad: squad),
              );
            },
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.white : Colors.white,
            opacity: isDark ? 0.12 : 1.0,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 236,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.amber.withOpacity(0.2),
                    child: Icon(Icons.groups, color: isDark ? Colors.amber.shade200 : Colors.amber, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          squad.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          squad.category.getName("ar"),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${squad.rating.toStringAsFixed(1)} | ${squad.memberIds.length} أعضاء',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                squad.state ?? 'موقع غير محدد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestList(List<RequestModel> requests, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: requests.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final req = requests[index];
          // Calculate remaining time
          String timeRemaining = "مفتوح";
          if (req.expiresAt != null) {
            final now = DateTime.now();
            final difference = req.expiresAt!.difference(now);
            if (difference.isNegative) {
              timeRemaining = "منتهي";
            } else if (difference.inDays > 0) {
              timeRemaining = "باقي ${difference.inDays} يوم";
            } else if (difference.inHours > 0) {
              timeRemaining = "باقي ${difference.inHours} ساعة";
            } else {
              timeRemaining = "باقي ${difference.inMinutes} دقيقة";
            }
          }

          return PremiumGlassCard(
            onTap: () {
              HapticFeedback.lightImpact();
              NavigationUtils.navigateSafely(
                context,
                RequestDetailsScreen(request: req),
              );
            },
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.white : Colors.white,
            opacity: isDark ? 0.12 : 1.0,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 236,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          req.category ?? 'طلب خدمة',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (timeRemaining == "منتهي") ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          timeRemaining,
                          style: TextStyle(
                            fontSize: 10,
                            color: (timeRemaining == "منتهي") ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    req.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.price != null ? '${req.price} ج' : 'غير محدد',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${req.offersCount} عروض',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostList(List<PostModel> posts, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          return PremiumGlassCard(
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Navigate to post details
            },
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.white : Colors.white,
            opacity: isDark ? 0.12 : 1.0,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 236,
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
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
                        ? Icon(Icons.shopping_bag, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          post.caption ?? 'منتج بدون اسم',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (post.category != null)
                          Text(
                            post.category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              post.price != null ? '${post.price} ج' : 'تواصل للسعر',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationList(List<UserModel> freelancers, bool isDark) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: freelancers.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final freelancer = freelancers[index];
          return PremiumGlassCard(
            onTap: () {
              HapticFeedback.lightImpact();
              NavigationUtils.navigateSafely(
                context,
                ProfileScreen(userId: freelancer.id),
              );
            },
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.white : Colors.white,
            opacity: isDark ? 0.12 : 1.0,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 236,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: (freelancer.profileImageUrl != null && freelancer.profileImageUrl!.isNotEmpty)
                        ? NetworkImage(freelancer.profileImageUrl!)
                        : null,
                    backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    child: (freelancer.profileImageUrl == null || freelancer.profileImageUrl!.isEmpty)
                        ? Icon(Icons.person, color: isDark ? Colors.white54 : Colors.grey.shade400, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                freelancer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (freelancer.isVerified)
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ),
                        if (freelancer.jobTitle != null && freelancer.jobTitle!.isNotEmpty)
                          Text(
                            freelancer.jobTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${freelancer.rating.toStringAsFixed(1)} (${freelancer.reviewsCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                freelancer.state ?? 'موقع غير محدد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceEstimationBox(String priceRange, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
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

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
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
      ),
    );
  }
}
