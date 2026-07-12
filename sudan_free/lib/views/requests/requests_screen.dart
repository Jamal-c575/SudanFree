import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/request_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/buttons/smart_draggable_fab.dart';
import '../../services/smart_guide_service.dart';
import '../../services/ai_guide_service.dart';
import 'add_request_screen.dart';
import 'request_details_screen.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';
import '../home/home_screen.dart'; // To access BottomBarVisibilityProvider

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  // ✅ FIX #3: Category uses English key for consistent filtering across languages
  String _selectedCategoryKey = 'All';
  final List<Map<String, String>> _categories = [
    {'ar': 'الكل',         'en': 'All'},
    {'ar': 'سيارات',       'en': 'Cars'},
    {'ar': 'عقارات',       'en': 'Real Estate'},
    {'ar': 'إلكترونيات',  'en': 'Electronics'},
    {'ar': 'ملابس',        'en': 'Clothes'},
    {'ar': 'خدمات',        'en': 'Services'},
    {'ar': 'أطعمة',        'en': 'Food'},
    {'ar': 'بناء',         'en': 'Construction'},
    {'ar': 'تجميل',        'en': 'Beauty'},
  ];

  AnimationController? _timerController;
  DateTime _now = DateTime.now();
  late Stream<List<RequestModel>> _requestsStream;

  // ✅ FIX #3: Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _requestsStream = FirestoreService().getRequests();
    // One timer for the whole screen — updates every second, automatically pauses when offstage!
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      });
    _timerController?.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userName = authProvider.user?.name ?? 'عزيزي';

      AiGuideService.showPageGuide(
        context,
        'الطلبات والمناقصات',
        userName,
      );
    });
  }

  @override
  void dispose() {
    _timerController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBarTop = bottomInset > 30 ? bottomInset + 8 + 62.0 : bottomInset + 14 + 62.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.marketplace, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: GlassContainer(
            enableBlur: true, // Enable real blur for the static AppBar
            blur: 15,
            opacity: isDark ? 0.4 : 0.8,
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: isDark ? 0.3 : 0.7),
            child: Container(),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: NestedScrollView(
                floatHeaderSlivers: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Consumer<BottomBarVisibilityProvider?>(
                        builder: (context, visibilityProvider, child) {
                          final isVisible = visibilityProvider?.isVisible ?? true;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isVisible ? 70 : 0,
                            curve: Curves.easeOutCubic,
                            clipBehavior: Clip.hardEdge,
                            decoration: const BoxDecoration(),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                child: GlassContainer(
                                  borderRadius: BorderRadius.circular(12),
                                  blur: 15,
                                  opacity: isDark ? 0.3 : 0.6,
                                  color: Theme.of(context).cardColor,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!.searchOffers,
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() => _searchQuery = '');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      filled: true,
                                      fillColor: Colors.transparent,
                                    ),
                                    onChanged: (value) {
                                      setState(() => _searchQuery = value.trim());
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final key = cat['en']!;
                                final label = locale == 'ar' ? cat['ar']! : cat['en']!;
                                final isSelected = _selectedCategoryKey == key;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedCategoryKey = key),
                                    child: GlassContainer(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      borderRadius: BorderRadius.circular(16),
                                      blur: 15,
                                      opacity: isSelected
                                          ? (isDark ? 0.3 : 0.4)
                                          : (isDark ? 0.1 : 0.2),
                                      color: isSelected
                                          ? AppColors.primary
                                          : Theme.of(context).cardColor,
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: isSelected ? 0.5 : 0.1)),
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 200),
                                        style: TextStyle(
                                          fontSize: isSelected ? 14 : 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color
                                                      ?.withValues(alpha: 0.6) ??
                                                  Colors.grey,
                                          fontFamily: 'Cairo',
                                        ),
                                        child: Center(child: Text(label)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ];
                },
                body: StreamBuilder<List<RequestModel>>(
                  stream: _requestsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerGrid(isDark);
                    }

                    var posts = snapshot.data ?? [];

                    if (_selectedCategoryKey != 'All') {
                      posts = posts.where((p) => (p.category ?? 'Services') == _selectedCategoryKey).toList();
                    }

                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      posts = posts.where((p) =>
                        p.text.toLowerCase().contains(q) ||
                        ((p.category ?? 'Services').toLowerCase().contains(q)) ||
                        (p.clientName.toLowerCase().contains(q))
                      ).toList();
                    }

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noActiveOffersRightNow,
                              style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.beTheFirstToPostAn,
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, navBarTop + 20),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: MarketplaceItemCard(
                            post: posts[index],
                            locale: locale,
                            currentUserId: currentUser?.id,
                            now: _now,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Custom Floating Draggable Fab
          if (currentUser != null)
            SmartDraggableFab(
              heroTag: 'add_market_post',
              icon: Icons.add_circle_outline,
              label: AppLocalizations.of(context)!.postOffer,
              locale: locale,
              initialBottom: MediaQuery.of(context).padding.bottom + 82.0,
              openBuilder: (context, openContainer) {
                return Scaffold(
                  backgroundColor: AppColors.background,
                  body: AddRequestBottomSheet(user: currentUser),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 250,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }
}

// ✅ FIX #2: MarketplaceItemCard is now a StatelessWidget
// The `now` clock is passed from the parent screen's shared Ticker
// — ZERO timers instead of one per card!
class MarketplaceItemCard extends StatelessWidget {
  final RequestModel post;
  final String locale;
  final String? currentUserId;
  final DateTime now; // ✅ Passed from screen-level Ticker

  const MarketplaceItemCard({
    super.key,
    required this.post,
    required this.locale,
    required this.now,
    this.currentUserId,
  });

  Duration get _timeLeft {
    final diff = post.expiresAt.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteOffer),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirestoreService().deleteRequest(post.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.deletedSuccessfully),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: post))),
      child: GlassContainer(
        blur: 20,
        opacity: isDark ? 0.2 : 0.8,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (post.allImageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: post.allImageUrls.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                ),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: Icon(Icons.campaign_outlined, size: 40, color: AppColors.primary)),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown & Category Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _timeLeft.inHours < 2
                              ? Colors.redAccent.withValues(alpha: 0.2)
                              : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _timeLeft.inHours < 2 ? Colors.red : Colors.orange,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 14,
                                color: _timeLeft.inHours < 2 ? Colors.red : Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '${_timeLeft.inHours.toString().padLeft(2, '0')}:'
                              '${(_timeLeft.inMinutes % 60).toString().padLeft(2, '0')}:'
                              '${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _timeLeft.inHours < 2 ? Colors.red : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final catKey = post.category ?? 'Services';
                          final displayCat = locale == 'ar' && catKey == 'Services' ? 'خدمات' : catKey; // Simple fallback
                          return Text(displayCat,
                              style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12));
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Text Content
                  Text(
                    post.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (post.locality != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${post.locality ?? ''} ${post.state != null ? '- ${post.state}' : ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  
                  if (post.price != null && post.price! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            '${post.price!.toStringAsFixed(0)} SDG',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Footer: User & Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: post.clientImageUrl != null
                                ? CachedNetworkImageProvider(post.clientImageUrl!)
                                : null,
                            child: post.clientImageUrl == null
                                ? const Icon(Icons.person, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(post.clientName,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      Row(
                        children: [
                          if (currentUserId == post.clientId)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                              onPressed: () => _deletePost(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (currentUserId == post.clientId) const SizedBox(width: 8),
                          GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.primary,
                            child: Text(
                              AppLocalizations.of(context)!.details,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
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
      ),
    );
  }
}
