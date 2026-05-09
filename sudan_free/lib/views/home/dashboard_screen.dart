import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../models/ad_model.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore/ad_service.dart';
import '../../services/cloudinary_service.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../views/widgets/ad_widget.dart';
import '../../core/routes/premium_page_route.dart';
import '../search/smart_search_delegate.dart';

class DashboardScreen extends StatefulWidget {
  /// Callback to switch to a specific tab in the parent HomeScreen
  final void Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  AdModel? _homeBannerAd;
  AdModel? _stripAd;
  bool _isLoadingAds = true;
  final AdService _adService = AdService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAds();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAds() async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser != null) {
      final results = await Future.wait([
        _adService.getTargetedAd(currentUser, placement: AdPlacement.homeBanner),
        _adService.getTargetedAd(currentUser, placement: AdPlacement.strip),
      ]);
      if (mounted) {
        setState(() {
          _homeBannerAd = results[0];
          _stripAd = results[1];
          _isLoadingAds = false;
        });
        // Record impressions
        if (_homeBannerAd != null) _adService.recordImpression(_homeBannerAd!.id);
        if (_stripAd != null) _adService.recordImpression(_stripAd!.id);
      }
    } else {
      if (mounted) setState(() => _isLoadingAds = false);
    }
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

    // Featured freelancers (top rated)
    final featuredFreelancers = List<UserModel>.from(userProvider.freelancers)
      ..sort((a, b) => b.rating.compareTo(a.rating));

    // Shops from user's region
    final nearbyShops = userProvider.shops.where((s) {
      if (currentUser.state == null) return true;
      return s.state == currentUser.state || s.state == null;
    }).toList();

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
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
                actions: [
                  // Notifications bell with badge
                  StreamBuilder<int>(
                    stream: FirestoreService().getUnreadNotificationsCount(currentUser.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
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

              // ═══════════ HOME BANNER AD ═══════════
              if (_homeBannerAd != null)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: AdWidget(
                          ad: _homeBannerAd!,
                          onTap: () => _adService.recordClick(_homeBannerAd!.id),
                        ),
                      ),
                    ),
                  ),
                )
              else if (_isLoadingAds)
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

              // ═══════════ FEATURED FREELANCERS ═══════════
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  context,
                  icon: Icons.workspace_premium,
                  title: locale == 'ar' ? 'مقدمو خدمات مميزون' : 'Top Professionals',
                  iconColor: AppColors.sudanGold,
                  onSeeAll: () => widget.onNavigateToTab?.call(1),
                  locale: locale,
                ),
              ),
              SliverToBoxAdapter(
                child: userProvider.isLoading && featuredFreelancers.isEmpty
                    ? _buildHorizontalCardShimmer(context)
                    : _buildFeaturedFreelancers(context, featuredFreelancers.take(10).toList(), locale, isDark),
              ),

              // ═══════════ STRIP AD ═══════════
              if (_stripAd != null)
                SliverToBoxAdapter(
                  child: _buildStripAd(context, _stripAd!, isDark),
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
                            user.jobTitle ?? user.getRoleDisplayName(locale),
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  // ────────────── Strip Ad (compact horizontal banner) ──────────────
  Widget _buildStripAd(BuildContext context, AdModel ad, bool isDark) {
    return GestureDetector(
      onTap: () async {
        _adService.recordClick(ad.id);
        if (ad.actionUrl != null && ad.actionUrl!.isNotEmpty) {
          final uri = Uri.tryParse(ad.actionUrl!);
          if (uri != null) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A3A5C), const Color(0xFF0D2B45)]
                : [AppColors.primary.withValues(alpha: 0.08), AppColors.secondary.withValues(alpha: 0.08)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.campaign, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (ad.description.isNotEmpty)
                    Text(
                      ad.description,
                      style: TextStyle(fontSize: 11, color: AppColors.softGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (ad.actionUrl != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'تصفح',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
