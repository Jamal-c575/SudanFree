import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../models/ad_model.dart';
import '../../services/firestore/ad_service.dart';
import '../../services/firestore/promotion_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/notification_polling_service.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../views/widgets/ad_widget.dart';
import '../../core/routes/premium_page_route.dart';
import '../search/smart_search_delegate.dart';
import '../settings/settings_screen.dart';
import '../../core/utils/job_titles_utils.dart';
import 'ad_details_screen.dart';
import 'filtered_providers_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Callback to switch to a specific tab in the parent HomeScreen
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  List<AdModel> _homeBannerAds = [];
  int _currentBannerAdIndex = 0;
  List<AdModel> _stripAds = [];
  int _currentStripAdIndex = 0;
  bool _isLoadingAds = true;
  final AdService _adService = AdService();
  final PromotionService _promotionService = PromotionService();
  List<PromotedUser> _promotedUsers = [];
  bool _isLoadingPromotions = true;
  PageController? _bannerPageController;
  Timer? _bannerAutoScrollTimer;
  Timer? _stripAutoScrollTimer;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAds();
      _fetchPromotions();
      
      // Initialize notification polling service
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.user;
      if (currentUser != null) {
        NotificationPollingService().setUserId(currentUser.id);
      }
    });
  }

  @override
  void dispose() {
    _bannerAutoScrollTimer?.cancel();
    _stripAutoScrollTimer?.cancel();
    _bannerPageController?.dispose();
    super.dispose();
  }

  Future<void> _fetchPromotions() async {
    setState(() => _isLoadingPromotions = true);
    final promoted = await _promotionService.getActivePromotions();
    if (!mounted) return;
    setState(() {
      _promotedUsers = promoted;
      _isLoadingPromotions = false;
    });
  }

  void _startBannerAutoScroll() {
    _bannerAutoScrollTimer?.cancel();
    if (_homeBannerAds.length <= 1) return;

    _bannerAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _homeBannerAds.isEmpty || _bannerPageController == null) return;
      final nextPage = (_currentBannerAdIndex + 1) % _homeBannerAds.length;
      _bannerPageController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _startStripAutoScroll() {
    _stripAutoScrollTimer?.cancel();
    if (_stripAds.length <= 1) return;

    _stripAutoScrollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _stripAds.isEmpty) return;
      setState(() {
        _currentStripAdIndex = (_currentStripAdIndex + 1) % _stripAds.length;
      });
    });
  }

  Future<void> _fetchAds() async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) {
      if (mounted) setState(() => _isLoadingAds = false);
      return;
    }

    setState(() => _isLoadingAds = true);

    final homeBannerAds = await _adService.getAdsForPlacement(currentUser, AdPlacement.homeBanner, limit: 4);
    final stripAds = await _adService.getAdsForPlacement(currentUser, AdPlacement.strip, limit: 3);

    if (!mounted) return;

    setState(() {
      _homeBannerAds = homeBannerAds;
      _stripAds = stripAds;
      _currentBannerAdIndex = 0;
      _currentStripAdIndex = 0;
      _isLoadingAds = false;
    });

    if (_homeBannerAds.isNotEmpty) {
      _adService.recordImpression(_homeBannerAds[0].id);
    }
    _startBannerAutoScroll();
    _startStripAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = authProvider.user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Partners for stories
    final allPartners = authProvider.partners.take(15).toList();
    final storyUsers = [
      ...allPartners.where((u) => u.isOnline),
      ...allPartners.where((u) => !u.isOnline),
    ];


    // Shops from user's region
    final nearbyShops = userProvider.shops.where((s) {
      if (currentUser.state == null) return true;
      return s.state == currentUser.state || s.state == null;
    }).toList();

    // Freelancers from user's region (prioritizing essential services)
    final nearbyFreelancers = List<UserModel>.from(userProvider.freelancers).where((f) {
      if (currentUser.state == null) return true;
      return f.state == currentUser.state;
    }).toList();

    final essentialKeywords = ['كهربائي', 'كهرباء', 'سباك', 'سباكة', 'ترحيل', 'نقل', 'ميكانيكي', 'صيانة', 'سيارات'];
    nearbyFreelancers.sort((a, b) {
      final aBio = '${a.jobTitle ?? ''} ${a.skills.join(' ')} ${a.bio ?? ''}'.toLowerCase();
      final bBio = '${b.jobTitle ?? ''} ${b.skills.join(' ')} ${b.bio ?? ''}'.toLowerCase();
      
      bool aEssential = essentialKeywords.any((k) => aBio.contains(k));
      bool bEssential = essentialKeywords.any((k) => bBio.contains(k));

      if (aEssential && !bEssential) return -1;
      if (!aEssential && bEssential) return 1;
      return b.rating.compareTo(a.rating); // Then by rating
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchAds();
            userProvider.fetchFreelancers(forceRefresh: true);
            userProvider.fetchShops(forceRefresh: true);
            authProvider.fetchPartners();
          },
          child: CustomScrollView(
            slivers: [
              // ═══════════ APP BAR with Profile + Notifications ═══════════
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leadingWidth: 56,
                leading: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PremiumPageRoute(page: const ProfileScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 12),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: currentUser.profileImageUrl != null
                          ? CachedNetworkImageProvider(
                              CloudinaryService.getOptimizedUrl(
                                currentUser.profileImageUrl!, width: 100, quality: 'auto'))
                          : null,
                      child: currentUser.profileImageUrl == null
                          ? Icon(Icons.person, size: 20, color: AppColors.primary)
                          : null,
                    ),
                  ),
                ),
                title: Text(
                  locale == 'ar' ? 'سودان فري' : 'SudanFree',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
                actions: [
                  // Notifications bell with badge (using polling instead of real-time stream)
                  Consumer<NotificationPollingService>(
                    builder: (context, pollingService, _) {
                      final count = pollingService.unreadCount;
                      return IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        icon: Badge(
                          isLabelVisible: count > 0,
                          label: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SettingsScreen(asBottomSheet: true),
                      );
                    },
                    icon: Icon(Icons.menu, color: isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              // ═══════════ SEARCH BAR ═══════════
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => showSearch(
                    context: context,
                    delegate: SmartSearchDelegate(),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.softGrey, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          locale == 'ar' ? 'ابحث في سودان فري...' : 'Search SudanFree...',
                          style: TextStyle(
                            color: AppColors.softGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ═══════════ STORIES (PARTNERS) ═══════════
              if (storyUsers.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildStoriesSection(context, storyUsers, locale, isDark),
                ),
              if (storyUsers.isEmpty && currentUser.partnerIds.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildStoriesShimmer(context),
                ),

              // ═══════════ HOME BANNER CAROUSEL ═══════════
              SliverToBoxAdapter(
                child: _buildHomeBannerCarousel(context, locale, isDark),
              ),

              // ═══════════ QUICK ACCESS CATEGORIES ═══════════
              SliverToBoxAdapter(
                child: _buildQuickCategories(context, locale),
              ),

              // ═══════════ PROMOTED SERVICES ═══════════
              if (_promotedUsers.isNotEmpty || _isLoadingPromotions)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    icon: Icons.star,
                    title: locale == 'ar' ? 'مُروّج لهم' : 'Featured Providers',
                    iconColor: AppColors.sudanGold,
                    onSeeAll: () => widget.onNavigateToTab?.call(1),
                    locale: locale,
                  ),
                ),
              if (_promotedUsers.isNotEmpty || _isLoadingPromotions)
                SliverToBoxAdapter(
                  child: _isLoadingPromotions
                      ? _buildHorizontalCardShimmer(context)
                      : _buildPromotedSection(context, locale, isDark),
                ),

              // ═══════════ RECOMMENDED FOR YOU ═══════════
              if (currentUser.role == UserRole.client)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    icon: Icons.recommend,
                    title: locale == 'ar' ? 'موصى به لك' : 'Recommended for You',
                    iconColor: AppColors.secondary,
                    onSeeAll: () => widget.onNavigateToTab?.call(1),
                    locale: locale,
                  ),
                ),
              if (currentUser.role == UserRole.client)
                SliverToBoxAdapter(
                  child: userProvider.isLoading && nearbyFreelancers.isEmpty
                      ? _buildHorizontalCardShimmer(context)
                      : _buildRecommendedSection(context, nearbyFreelancers.take(6).toList(), locale, isDark),
                ),

              // ═══════════ NEARBY FREELANCERS (ESSENTIALS) ═══════════
              if (nearbyFreelancers.isNotEmpty || userProvider.isLoading)
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    icon: Icons.handyman,
                    title: locale == 'ar' ? 'خدمات في منطقتك' : 'Services Near You',
                    iconColor: AppColors.secondary,
                    onSeeAll: () => widget.onNavigateToTab?.call(1),
                    locale: locale,
                  ),
                ),
              if (nearbyFreelancers.isNotEmpty || userProvider.isLoading)
                SliverToBoxAdapter(
                  child: userProvider.isLoading && nearbyFreelancers.isEmpty
                      ? _buildHorizontalCardShimmer(context)
                      : _buildFeaturedFreelancers(context, nearbyFreelancers.take(10).toList(), locale, isDark),
                ),

              // ═══════════ STRIP AD ═══════════
              if (_stripAds.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildStripAd(context, _stripAds[_currentStripAdIndex], isDark),
                ),

              // ═══════════ NEARBY SHOPS ═══════════
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  icon: Icons.storefront,
                  title: locale == 'ar' ? 'متاجر في منطقتك' : 'Shops Near You',
                  iconColor: AppColors.desertOrange,
                  onSeeAll: () => widget.onNavigateToTab?.call(2),
                  locale: locale,
                ),
              ),
              SliverToBoxAdapter(
                child: userProvider.isLoading && nearbyShops.isEmpty
                    ? _buildHorizontalCardShimmer(context)
                    : _buildNearbyShops(context, nearbyShops.take(10).toList(), locale, isDark),
              ),

              // Bottom padding for floating nav bar
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────── Section Header ──────────────
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onSeeAll,
    required String locale,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale == 'ar' ? 'عرض الكل' : 'See All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  locale == 'ar' ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────── Stories Section ──────────────
  Widget _buildStoriesSection(BuildContext context, List<UserModel> users, String locale, bool isDark) {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 4, top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              PremiumPageRoute(page: ProfileScreen(userId: user.id)),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: locale == 'ar' ? 12 : 0, right: locale == 'ar' ? 0 : 12),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: user.role == UserRole.shop
                                ? [Colors.amber, Colors.orange]
                                : [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(2.5),
                        child: CircleAvatar(
                          radius: 31,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          backgroundImage: user.profileImageUrl != null
                              ? CachedNetworkImageProvider(
                                  CloudinaryService.getOptimizedUrl(
                                    user.profileImageUrl!, width: 150, quality: 'auto'))
                              : null,
                          child: user.profileImageUrl == null
                              ? Icon(
                                  user.role == UserRole.shop ? Icons.store : Icons.person,
                                  color: AppColors.textSecondary,
                                  size: 24,
                                )
                              : null,
                        ),
                      ),
                      if (user.isOnline)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 68,
                    child: Text(
                      user.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildStoriesShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 4, top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: [
                Container(
                  width: 68, height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50, height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomeBannerCarousel(BuildContext context, String locale, bool isDark) {
    if (_isLoadingAds) {
      return Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_homeBannerAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _bannerPageController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerAdIndex = index;
              });
            },
            itemCount: _homeBannerAds.length,
            itemBuilder: (context, index) {
              final ad = _homeBannerAds[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: GestureDetector(
                  onTap: () {
                    _adService.recordImpression(ad.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
                    );
                  },
                  child: AdWidget(
                    ad: ad,
                    onTap: () {
                      _adService.recordImpression(ad.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (_homeBannerAds.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _homeBannerAds.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentBannerAdIndex == index ? 16 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _currentBannerAdIndex == index
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickCategories(BuildContext context, String locale) {
    final categories = [
      {
        'title': locale == 'ar' ? 'الأقرب إليك' : 'Near You',
        'icon': Icons.location_on,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredProvidersScreen(filterType: FilterType.nearYou, title: locale == 'ar' ? 'الأقرب إليك' : 'Near You'))),
      },
      {
        'title': locale == 'ar' ? 'الأعلى تقييماً' : 'Top Rated',
        'icon': Icons.star,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredProvidersScreen(filterType: FilterType.topRated, title: locale == 'ar' ? 'الأعلى تقييماً' : 'Top Rated'))),
      },
      {
        'title': locale == 'ar' ? 'الجديد' : 'New',
        'icon': Icons.fiber_new,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredProvidersScreen(filterType: FilterType.newest, title: locale == 'ar' ? 'الجديد' : 'New'))),
      },
      {
        'title': locale == 'ar' ? 'المتاجر' : 'Shops',
        'icon': Icons.storefront,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredProvidersScreen(filterType: FilterType.shops, title: locale == 'ar' ? 'المتاجر' : 'Shops'))),
      },
      {
        'title': locale == 'ar' ? 'الفئات' : 'Categories',
        'icon': Icons.category,
        // Categories can still navigate to search/tab 1 if preferred, or open a special sheet
        // but for consistency, we'll route it to the filtered screen for now
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => FilteredProvidersScreen(filterType: FilterType.categories, title: locale == 'ar' ? 'كل الفئات' : 'All Categories'))),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = categories[index];
          return GestureDetector(
            onTap: item['action'] as void Function(),
            child: Container(
              width: 92,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: categories.length,
      ),
    );
  }

  // ────────────── Featured Freelancers (Horizontal Scroll) ──────────────
  Widget _buildFeaturedFreelancers(BuildContext context, List<UserModel> freelancers, String locale, bool isDark) {
    if (freelancers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          locale == 'ar' ? 'لا يوجد مقدمو خدمات حالياً' : 'No professionals yet',
          style: TextStyle(color: AppColors.softGrey),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: freelancers.length,
        itemBuilder: (context, index) {
          final user = freelancers[index];
          return _AnimatedCardItem(
            index: index,
            child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              PremiumPageRoute(page: ProfileScreen(userId: user.id)),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE8ECF0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Profile image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: user.profileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: CloudinaryService.getOptimizedUrl(
                                user.profileImageUrl!, width: 300, quality: 'auto'),
                              fit: BoxFit.cover,
                              memCacheWidth: 300,
                              placeholder: (_, __) => Center(
                                child: Icon(Icons.person, size: 36, color: Colors.white54),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(Icons.person, size: 36, color: Colors.white54),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.person, size: 36, color: Colors.white54),
                            ),
                    ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.jobTitle?.isNotEmpty == true 
                                ? JobTitlesUtils.getLocalizedTitle(user.jobTitle!, locale) 
                                : (user.skills.isNotEmpty 
                                    ? user.skills.map((s) => JobTitlesUtils.getLocalizedTitle(s, locale)).join('، ') 
                                    : user.getRoleDisplayName(locale)),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 10, color: AppColors.softGrey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  user.state ?? (locale == 'ar' ? 'غير محدد' : 'Unknown'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.softGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: AppColors.sudanGold),
                              const SizedBox(width: 2),
                              Text(
                                user.rating > 0
                                    ? user.rating.toStringAsFixed(1)
                                    : (locale == 'ar' ? 'جديد' : 'New'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                              const Spacer(),
                              if (user.isOnline)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    locale == 'ar' ? 'متاح' : 'Online',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  // ────────────── Nearby Shops (Horizontal Scroll) ──────────────
  Widget _buildNearbyShops(BuildContext context, List<UserModel> shops, String locale, bool isDark) {
    if (shops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          locale == 'ar' ? 'لا يوجد متاجر حالياً' : 'No shops yet',
          style: TextStyle(color: AppColors.softGrey),
        ),
      );
    }

    return SizedBox(
      height: 175,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          return _AnimatedCardItem(
            index: index,
            child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              PremiumPageRoute(page: ProfileScreen(userId: shop.id)),
            ),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE8ECF0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Shop image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 85,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.sudanGradient,
                      ),
                      child: shop.profileImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: CloudinaryService.getOptimizedUrl(
                                shop.profileImageUrl!, width: 300, quality: 'auto'),
                              fit: BoxFit.cover,
                              memCacheWidth: 300,
                              placeholder: (_, __) => Center(
                                child: Icon(Icons.store, size: 32, color: Colors.white54),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(Icons.store, size: 32, color: Colors.white54),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.store, size: 32, color: Colors.white54),
                            ),
                    ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (shop.shopCategory != null)
                            Text(
                              shop.getShopCategoryName(locale),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.desertOrange,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: AppColors.softGrey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  shop.state ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.softGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }

  // ────────────── Shimmer for horizontal cards ──────────────
  Widget _buildHorizontalCardShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStripAd(BuildContext context, AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () async {
        _adService.recordClick(ad.id);
        if (ad.actionUrl != null && ad.actionUrl!.isNotEmpty) {
          // Handle different action types
          if (ad.actionUrl!.startsWith('http')) {
            // External URL
            // Note: url_launcher is not imported, but we can add it back if needed
            // For now, navigate to ad details
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
            );
          } else {
            // Internal navigation (could be a route like '/shops' or '/services')
            // For now, navigate to ad details
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
            );
          }
        } else {
          // Default: navigate to ad details
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: ad)),
          );
        }
      },
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with shimmer loading
            CachedNetworkImage(
              imageUrl: CloudinaryService.getOptimizedUrl(
                ad.mediaUrl, 
                width: 800, 
                height: 250, 
                quality: 'auto',
                extraTransformations: ['f_auto']
              ),
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildShimmerLoader(isDark),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A3A5C), const Color(0xFF0D2B45)]
                        : [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.white70, size: 32),
                ),
              ),
            ),

            // Dark Gradient Overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'إعلان ممول',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ad.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (ad.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            ad.description,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'تصفح',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Auto-rotation indicator for multiple ads
            if (_stripAds.length > 1)
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: List.generate(
                    _stripAds.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentStripAdIndex == index ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _currentStripAdIndex == index 
                            ? Colors.white.withValues(alpha: 0.9) 
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [Colors.grey[850]!, Colors.grey[800]!, Colors.grey[850]!]
              : [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // ────────────── Trending Services (Horizontal Scroll with Badges) ──────────────
  // ────────────── Promoted Section ──────────────
  Widget _buildPromotedSection(BuildContext context, String locale, bool isDark) {
    if (_promotedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _promotedUsers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final promo = _promotedUsers[index];
          return _AnimatedCardItem(
            index: index,
            child: _buildPromotedCard(context, promo, locale, isDark),
          );
        },
      ),
    );
  }

  Widget _buildPromotedCard(BuildContext context, PromotedUser promo, String locale, bool isDark) {
    final user = promo.user!;
    final jobTitle = user.jobTitle?.trim();
    final firstSkill = user.skills.isNotEmpty ? user.skills.first.trim() : null;
    final String roleLabel;
    if (user.role == UserRole.shop) {
      roleLabel = user.shopCategory != null 
          ? '${locale == 'ar' ? 'متجر' : 'Shop'} • ${user.shopCategory!.name}'
          : (locale == 'ar' ? 'متجر' : 'Shop');
    } else if (jobTitle != null && jobTitle.isNotEmpty) {
      roleLabel = jobTitle; // مبرمج، مدرس، خياط...
    } else if (firstSkill != null && firstSkill.isNotEmpty) {
      roleLabel = firstSkill; // أول مهارة كبديل
    } else {
      // بديل حسب نوع الحساب
      switch (user.role) {
        case UserRole.freelancer:
          roleLabel = locale == 'ar' ? 'مقدم خدمات فنية' : 'Freelancer';
        case UserRole.techService:
          roleLabel = locale == 'ar' ? 'خدمات تقنية' : 'Tech Service';
        case UserRole.privateService:
          roleLabel = locale == 'ar' ? 'خدمات خاصة' : 'Private Service';
        default:
          roleLabel = locale == 'ar' ? 'مقدم خدمة' : 'Service Provider';
      }
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
      ),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.sudanGold.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.sudanGold.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Promoted badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sudanGold, AppColors.sudanGold.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 11, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      locale == 'ar' ? 'مُروّج' : 'Promoted',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Profile image side
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.sudanGold.withValues(alpha: 0.15),
                        backgroundImage: user.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                CloudinaryService.getOptimizedUrl(user.profileImageUrl!, width: 150, quality: 'auto'))
                            : null,
                        child: user.profileImageUrl == null
                            ? Icon(Icons.person, size: 28, color: AppColors.sudanGold)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 13, color: AppColors.sudanGold),
                            const SizedBox(width: 2),
                            Text(
                              user.rating.toStringAsFixed(1),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sudanGold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Text side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18),
                        // Name
                        Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Role / Job title
                        Text(
                          roleLabel,
                          style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Location
                        if (user.state != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: AppColors.softGrey),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  '${user.locality ?? ''} ${user.state ?? ''}',
                                  style: TextStyle(fontSize: 11, color: AppColors.softGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        // Promo text
                        Expanded(
                          child: Text(
                            promo.promoText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────── Recommended Section (Personalized) ──────────────
  Widget _buildRecommendedSection(BuildContext context, List<UserModel> freelancers, String locale, bool isDark) {
    if (freelancers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          locale == 'ar' ? 'لا توجد توصيات حالياً' : 'No recommendations yet',
          style: TextStyle(color: AppColors.softGrey),
        ),
      );
    }

    return Container(
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: freelancers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final freelancer = freelancers[index];
          return _AnimatedCardItem(
            index: index,
            child: _buildRecommendedCard(context, freelancer, locale, isDark),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedCard(BuildContext context, UserModel freelancer, String locale, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(userId: freelancer.id)),
      ),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Recommended badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  locale == 'ar' ? 'موصى' : 'Rec',
                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    backgroundImage: freelancer.profileImageUrl != null
                        ? CachedNetworkImageProvider(
                            CloudinaryService.getOptimizedUrl(freelancer.profileImageUrl!, width: 80, quality: 'auto'))
                        : null,
                    child: freelancer.profileImageUrl == null
                        ? Icon(Icons.person, size: 16, color: AppColors.secondary)
                        : null,
                  ),
                  const SizedBox(height: 6),

                  // Name
                  Text(
                    freelancer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),

                  // Job title
                  Text(
                    freelancer.jobTitle ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.softGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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

/// Staggered animation wrapper for horizontal card items
class _AnimatedCardItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCardItem({required this.index, required this.child});

  @override
  State<_AnimatedCardItem> createState() => _AnimatedCardItemState();
}

class _AnimatedCardItemState extends State<_AnimatedCardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger the animation based on index
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
