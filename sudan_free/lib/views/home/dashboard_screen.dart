import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/common/verification_badge.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/home/motivational_quotes_carousel.dart';
import '../../models/user_model.dart';
import '../../models/ad_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/firestore/ad_service.dart';
import '../../services/notification_polling_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/common/morph_transition.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../core/routes/premium_page_route.dart';
import '../search/smart_search_delegate.dart';
import '../settings/settings_screen.dart';
import 'ad_details_screen.dart';
import 'filtered_providers_screen.dart';
import '../map/map_explorer_screen.dart';
import '../home/home_screen.dart'; // To access BottomBarVisibilityProvider
import '../../services/ai_guide_service.dart';
import '../../widgets/home/ai_recommendations_widget.dart';
import '../../widgets/home/recommended_users_widget.dart';
import 'package:sudan_free/utils/app_haptics.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/optimized_network_image.dart';
import '../../core/utils/job_titles_utils.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/home/sudanese_landmarks_carousel.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import "package:sudan_free/providers/partners_provider.dart";

class DashboardScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const DashboardScreen({super.key, this.onNavigateToTab});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  List<AdModel> _homeBannerAds = [];
  List<AdModel> _stripAds = [];
  int _currentBannerAdIndex = 0;
  bool _isLoadingAds = true;
  final AdService _adService = AdService();
  PageController? _bannerPageController;
  Timer? _bannerAutoScrollTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAds();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        NotificationPollingService().setUserId(authProvider.user!.id);
        context.read<PartnersProvider>().fetchPartners();
        AiGuideService.showPageGuide(
          context, 
          'الصفحة الرئيسية', 
          authProvider.user!.name,
        );
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerAutoScrollTimer?.cancel();
    if (_homeBannerAds.length <= 1) return;
    _bannerAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _homeBannerAds.isEmpty || _bannerPageController == null) {
        return;
      }
      final nextPage = (_currentBannerAdIndex + 1) % _homeBannerAds.length;
      _bannerPageController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchAds() async {
    final currentUser = context.read<AuthProvider>().user;
    setState(() => _isLoadingAds = true);
    final homeBannerAds = await _adService
        .getAdsForPlacement(currentUser, AdPlacement.homeBanner, limit: 4);
    final stripAds = await _adService
        .getAdsForPlacement(currentUser, AdPlacement.strip, limit: 1);
    if (!mounted) return;
    setState(() {
      _homeBannerAds = homeBannerAds;
      _stripAds = stripAds;
      _currentBannerAdIndex = 0;
      _isLoadingAds = false;
    });
    if (_homeBannerAds.isNotEmpty) {
      _adService.recordImpression(_homeBannerAds[0].id);
    }
    if (_stripAds.isNotEmpty) {
      _adService.recordImpression(_stripAds[0].id);
    }
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _bannerAutoScrollTimer?.cancel();
    _bannerPageController?.dispose();
    super.dispose();
  }

  String _getStoreTypeDisplay(UserModel u, String locale) {
    final loc = AppLocalizations.of(context);
    if (u.shopCategory == ShopCategory.beauty) {
      return loc?.beauty ?? 'Beauty';
    }
    // Since we don't have an explicit 'online'/'local' field in UserModel, we assume local by default,
    // or maybe based on if they have a physical address? Let's just use local unless online is specified in their bio/title
    final isOnline = u.bio?.toLowerCase().contains('online') == true ||
        u.jobTitle?.toLowerCase().contains('online') == true;
    if (isOnline) return loc?.onlineStore ?? 'Online Store';
    return loc?.localStore ?? 'Local Store';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentUser = authProvider.user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    if (currentUser == null) {
      return _buildDashboardShimmer();
    }

    final nearbyShops = userProvider.shops
        .where((s) => currentUser.state == null || s.state == currentUser.state)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final nearbyFreelancers = userProvider.freelancers
        .where((f) => currentUser.state == null || f.state == currentUser.state)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    Theme.of(context).primaryColor.withValues(alpha: 0.15)
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchAds();
            userProvider.fetchFreelancers(forceRefresh: true);
            userProvider.fetchShops(forceRefresh: true);
            context.read<PartnersProvider>().fetchPartners(forceRefresh: true);
          },
          child: CustomScrollView(
          slivers: [
            SliverAppBar(
              stretch: true,
              pinned: true,
              floating: false,
              snap: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: const FlexibleSpaceBar(
                stretchModes: [StretchMode.zoomBackground],
                background: SudaneseLandmarksCarousel(),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.zero,
                  enableBlur: true,
                  blur: 10,
                  color: Colors.black.withValues(alpha: 0.3),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      builder: (_) => const SettingsScreen(asBottomSheet: true),
                    );
                  },
                ),
              ),
            ),
            title: GlassContainer(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                enableBlur: true,
                blur: 10,
                color: Colors.black.withValues(alpha: 0.3),
                child: Text(
                  AppLocalizations.of(context)!.sudanfree,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(12),
                    padding: EdgeInsets.zero,
                    enableBlur: true,
                    blur: 10,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: OpenContainer(
                      transitionDuration: const Duration(milliseconds: 700),
                      transitionType: ContainerTransitionType.fadeThrough,
                      closedElevation: 0,
                      closedColor: Colors.transparent,
                      middleColor: Colors.transparent,
                      openBuilder: (context, _) => const MapExplorerScreen(),
                      closedBuilder: (context, openContainer) {
                        return IconButton(
                          onPressed: openContainer,
                          icon: const Icon(Icons.map_outlined, color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
                Consumer<NotificationPollingService>(
                  builder: (context, pollingService, _) {
                    final count = pollingService.unreadCount;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                      child: GlassContainer(
                        borderRadius: BorderRadius.circular(12),
                        padding: EdgeInsets.zero,
                        enableBlur: true,
                        blur: 10,
                        color: Colors.black.withValues(alpha: 0.3),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PremiumPageRoute(page: const NotificationsScreen()),
                            );
                          },
                          icon: Badge(
                            isLabelVisible: count > 0,
                            label: Text(count > 99 ? '99+' : count.toString()),
                            child: const Icon(Icons.notifications_outlined, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(30),
                    padding: const EdgeInsets.all(2),
                    enableBlur: true,
                    blur: 10,
                    color: Colors.black.withValues(alpha: 0.3),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          PremiumPageRoute(
                              page: ProfileScreen(userId: currentUser.id))),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.transparent,
                        backgroundImage: currentUser.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                CloudinaryService.getOptimizedUrl(
                                    currentUser.profileImageUrl!,
                                    width: 100,
                                    quality: 'auto'))
                            : null,
                        child: currentUser.profileImageUrl == null
                            ? const Icon(Icons.person,
                                size: 20, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: Consumer<BottomBarVisibilityProvider?>(
                  builder: (context, visibilityProvider, child) {
                    final isVisible = visibilityProvider?.isVisible ?? true;
                    return SizedBox(
                      height: 70,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: isVisible
                            ? SingleChildScrollView(
                                key: const ValueKey('searchBar'),
                                physics: const NeverScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: GlassContainer(
                                    borderRadius: BorderRadius.circular(30),
                                    padding: EdgeInsets.zero,
                                    enableBlur: true,
                                    blur: 10,
                                    child: TextField(
                                      readOnly: true,
                                      onTap: () {
                                        AppHaptics.lightImpact();
                                        showSearch(
                                            context: context,
                                            delegate: SmartSearchDelegate());
                                      },
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(context)!.searchSudanfree,
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 0, horizontal: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(30),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                key: const ValueKey('motivationalQuotes'),
                                onTap: () {
                                  AppHaptics.lightImpact();
                                  showSearch(
                                      context: context,
                                      delegate: SmartSearchDelegate());
                                },
                                child: const MotivationalQuotesCarousel(),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // AI Recommendations Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(16),
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      title: const Text('مقترح خصيصاً لك 🎯', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      children: [
                        const AIRecommendationsWidget(title: ''),
                        Consumer<LocaleProvider>(
                          builder: (context, locale, _) => RecommendedUsersWidget(
                            isAr: locale.isArabic,
                            showTitle: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(duration: 600.ms).slideY(begin: 0.1),
            ),
            if (_isLoadingAds)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: Shimmer.fromColors(
                    baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                    highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              )
            else if (_homeBannerAds.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _bannerPageController,
                    onPageChanged: (index) =>
                        setState(() => _currentBannerAdIndex = index),
                    itemCount: _homeBannerAds.length,
                    itemBuilder: (context, index) {
                      final ad = _homeBannerAds[index];
                      return MorphTransition(
                        openScreen: AdDetailsScreen(ad: ad),
                        closedBuilder: (context, openContainer) => GestureDetector(
                          onTap: () {
                            AppHaptics.lightImpact();
                            _adService.recordImpression(ad.id);
                            openContainer();
                          },
                        child: GlassCard(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          borderRadius: 16,
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                OptimizedNetworkImage(
                                  imageUrl: ad.mediaUrl,
                                  quality: ImageQuality.medium,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.7),
                                        Colors.transparent
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                  child: Text(
                                    ad.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade700.withValues(alpha: 0.9),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.campaign, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          ad.advertiserName != null && ad.advertiserName!.isNotEmpty
                                              ? 'إعلان من ${ad.advertiserName}'
                                              : 'إعلان ممول',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                           ), // Stack
                         ), // ClipRRect
                       ), // GlassCard
                     ), // GestureDetector
                   ); // MorphTransition
                   },
                  ),
                ),
              ),


            // ✅ Improved Quick Access Buttons (Horizontal scroll, small cards)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 74,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.22,
                        child: _buildCompactActionCard(
                            context,
                            AppLocalizations.of(context)!.services,
                            Icons.handyman,
                            FilteredProvidersScreen(
                                filterType: FilterType.freelancersNearYou,
                                title: AppLocalizations.of(context)!.services)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.22,
                        child: _buildCompactActionCard(
                            context,
                            AppLocalizations.of(context)!.shops,
                            Icons.storefront,
                            FilteredProvidersScreen(
                                filterType: FilterType.shops,
                                title: AppLocalizations.of(context)!.shops)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.22,
                        child: _buildCompactActionCard(
                            context,
                            AppLocalizations.of(context)!.strNew,
                            Icons.fiber_new,
                            FilteredProvidersScreen(
                                filterType: FilterType.newest,
                                title: AppLocalizations.of(context)!.strNew)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.22,
                        child: _buildCompactActionCard(
                            context,
                            AppLocalizations.of(context)!.top,
                            Icons.star,
                            FilteredProvidersScreen(
                                filterType: FilterType.topRated,
                                title: AppLocalizations.of(context)!.topRated)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.22,
                        child: _buildCompactActionCard(
                            context,
                            AppLocalizations.of(context)!.nearest,
                            Icons.location_on,
                            FilteredProvidersScreen(
                                filterType: FilterType.nearYou,
                                title: AppLocalizations.of(context)!.nearest)),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1),
            ),

            _buildSectionHeader(
                AppLocalizations.of(context)!.servicesNearYou,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FilteredProvidersScreen(
                            filterType: FilterType.freelancersNearYou,
                            title: AppLocalizations.of(context)!.servicesNearYou)))),
            SliverToBoxAdapter(
              child: userProvider.isLoading
                  ? _buildShimmerList()
                  : _buildHorizontalUserList(
                      context, nearbyFreelancers.take(10).toList(), locale),
            ),
            _buildSectionHeader(
                AppLocalizations.of(context)!.shopsNearYou,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FilteredProvidersScreen(
                            filterType: FilterType.shopsNearYou,
                            title: AppLocalizations.of(context)!.shopsNearYou)))),
            SliverToBoxAdapter(
              child: userProvider.isLoading
                  ? _buildShimmerList()
                  : _buildHorizontalUserList(
                      context, nearbyShops.take(10).toList(), locale),
            ),
            if (_stripAds.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      AppHaptics.lightImpact();
                      _adService.recordClick(_stripAds[0].id);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: _stripAds[0])));
                    },
                    child: GlassContainer(
                      blur: 10,
                      opacity: 0.8,
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.passthrough,
                          children: [
                            CachedNetworkImage(
                              imageUrl: _stripAds[0].mediaUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[300]),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade700.withValues(alpha: 0.9),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.campaign, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      _stripAds[0].advertiserName != null && _stripAds[0].advertiserName!.isNotEmpty
                                          ? 'إعلان من ${_stripAds[0].advertiserName}'
                                          : 'إعلان ممول',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // ✅ Removed Community Section completely from DashboardScreen
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      ),
    );
  }

  // ✅ New Compact Action Card (70x70)
  Widget _buildCompactActionCard(
      BuildContext context, String title, IconData icon, Widget openScreen) {
    return MorphTransition(
      openScreen: openScreen,
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: GlassContainer(
          height: 70,
          borderRadius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                AppHaptics.lightImpact();
                onSeeAll();
              },
              child: Text(AppLocalizations.of(context)!.seeAll),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.35,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: const CircleAvatar(radius: 25, backgroundColor: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(width: 120, height: 20, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 24),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(width: 100, height: 20, color: Colors.white),
              ),
              const SizedBox(height: 12),
              _buildShimmerList(),
              const SizedBox(height: 24),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(width: 100, height: 20, color: Colors.white),
              ),
              const SizedBox(height: 12),
              _buildShimmerList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalUserList(
      BuildContext context, List<UserModel> users, String locale) {
    if (users.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.noDataAvailable,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 200, // ✅ Increased height to look less square (more professional)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final u = users[index];
          final String translatedJobTitle =
              (u.jobTitle != null && u.jobTitle!.isNotEmpty)
                  ? JobTitlesUtils.getLocalizedTitle(u.jobTitle!, locale)
                  : (u.skills.isNotEmpty
                      ? JobTitlesUtils.getLocalizedTitle(u.skills.first, locale)
                      : '');

          // ✅ FIX #4: RepaintBoundary isolates each card's GPU layer
          return RepaintBoundary(
            child: MorphTransition(
              openScreen: ProfileScreen(userId: u.id),
              closedBuilder: (context, openContainer) => GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact();
                  openContainer();
                },
            child: GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              borderRadius: 16,
              padding: EdgeInsets.zero,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * (u.isShop ? 0.38 : 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: '${u.id}_profile',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: u.profileImageUrl != null
                                  ? OptimizedNetworkImage(
                                      imageUrl: u.profileImageUrl!,
                                      quality: ImageQuality.thumbnail,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      child: Icon(
                                        u.isShop ? Icons.storefront : Icons.person,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                    ),
                            ),
                          ),
                          // Badge Overlay
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: u.isShop ? Colors.blue.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(u.isShop ? Icons.store : Icons.handyman, size: 10, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    u.isShop ? (AppLocalizations.of(context)!.shop) : (AppLocalizations.of(context)!.artisan),
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(u.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                SmartVerificationBadge(user: u, size: 12),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u.isShop
                                  ? u.getShopCategoryName(locale)
                                  : translatedJobTitle,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (u.isShop)
                              Text(
                                _getStoreTypeDisplay(u, locale),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.7),
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                              ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 12, color: Colors.orange),
                                    const SizedBox(width: 2),
                                    Text(u.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
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
              ), // Close GestureDetector
            ), // Close MorphTransition
          ); // Close RepaintBoundary
        },
      ),
    );
  }
}
