import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/posts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../widgets/common/shimmer_placeholders.dart';
import '../../widgets/cards/post_card.dart';
import '../../widgets/common/staggered_animated_widget.dart';
import '../../widgets/common/empty_state_widget.dart';
import 'create_post_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore/ad_service.dart';
import '../../models/ad_model.dart';
import '../../views/widgets/ad_widget.dart';
import '../../views/home/ad_details_screen.dart';
import '../../widgets/inputs/smart_search_field.dart';

class PostsFeedScreen extends StatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  State<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends State<PostsFeedScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PostCategoryGroup? _selectedGroup;
  bool _showSearch = false;
  Timer? _heartbeatTimer;
  Timer? _scrollDebounceTimer;

  // ── Smart Ad System ──
  List<AdModel> _ads = [];           // جميع الإعلانات النشطة
  bool _isFirstLoad = true;          // تحديد موضع الإعلان عند التحميل الأول
  final _random = Random();
  final AdService _adService = AdService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsProvider>().fetchPosts();
      context.read<AuthProvider>().fetchPartners();
      _fetchAds();
      _sendHeartbeat();
      _heartbeatTimer = Timer.periodic(const Duration(minutes: 15), (_) => _sendHeartbeat());
    });
    
    // Infinite Scroll Listener with debounce to prevent duplicate fetches
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        // Debounce: only trigger once per 500ms to avoid multiple rapid requests
        _scrollDebounceTimer?.cancel();
        _scrollDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          context.read<PostsProvider>().fetchMorePosts();
        });
      }
    });
  }

  Future<void> _fetchAds() async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) return;

    try {
      final ads = await _adService.getAdsForPlacement(
        currentUser,
        AdPlacement.communityFeed,
        limit: 8, // جلب حتى 8 إعلانات لتوزيعها في التغذية
      );
      if (mounted) {
        setState(() {
          _ads = ads;
        });
        // تسجيل الظهور لكل إعلان
        for (final ad in ads) {
          _adService.recordImpression(ad.id);
        }
      }
    } catch (e) {
      debugPrint('PostsFeed: Error fetching ads: $e');
    }
  }

  /// يبني قائمة مدمجة من المنشورات والإعلانات بشكل ذكي
  /// ─ الإعلان الأول يظهر في الأعلى فقط عند التحميل الأول
  /// ─ بعد ذلك تظهر بعد 4–8 منشورات بشكل عشوائي
  List<dynamic> _buildMixedFeed(List<PostModel> posts) {
    if (_ads.isEmpty || _searchQuery.isNotEmpty) return posts;

    final List<dynamic> mixed = [];
    int adIndex = 0;

    // ─ التحميل الأول: الإعلان في الأعلى مباشرة (index 0)
    if (_isFirstLoad && adIndex < _ads.length) {
      mixed.add(_ads[adIndex++]);
    }

    // ─ باقي المنشورات مع توزيع الإعلانات بشكل عشوائي (4–8 منشورات)
    int nextAdAfter = _isFirstLoad ? (4 + _random.nextInt(5)) : (2 + _random.nextInt(3)); // 4-8 أولاً، 2-4 بعد التحديث
    int postsSinceLastAd = 0;

    for (final post in posts) {
      mixed.add(post);
      postsSinceLastAd++;

      if (adIndex < _ads.length && postsSinceLastAd >= nextAdAfter) {
        mixed.add(_ads[adIndex++]);
        postsSinceLastAd = 0;
        nextAdAfter = 4 + _random.nextInt(5); // 4-8 للإعلانات التالية
      }
    }

    // تأكد من ظهور إعلان واحد على الأقل إذا كانت المنشورات قليلة جداً
    if (adIndex == 0 && _ads.isNotEmpty && posts.isNotEmpty) {
       mixed.add(_ads[adIndex++]);
    }

    return mixed;
  }

  void _sendHeartbeat() {
    final uid = context.read<AuthProvider>().user?.id;
    if (uid != null) {
      FirestoreService().updateLastActive(uid);
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PostModel> _filterPosts(List<PostModel> posts) {
    if (_searchQuery.isEmpty && _selectedGroup == null) {
       final sorted = List<PostModel>.from(posts);
       // Combined sorting: Latest + Interactive Auto-sort
       // Every interaction adds virtual 2 hours to the post's "newness"
       sorted.sort((a, b) {
         final scoreA = a.createdAt.millisecondsSinceEpoch + ((a.totalReactions + a.commentsCount) * 7200000);
         final scoreB = b.createdAt.millisecondsSinceEpoch + ((b.totalReactions + b.commentsCount) * 7200000);
         return scoreB.compareTo(scoreA);
       });
       return sorted;
    }
    
    final filtered = posts.where((post) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesCaption = post.caption?.toLowerCase().contains(query) ?? false;
        final matchesUser = post.userName.toLowerCase().contains(query);
        if (!matchesCaption && !matchesUser) return false;
      }
      if (_selectedGroup != null) {
        if (post.category == null) return false;
        try {
          final postCat = PostCategory.values.firstWhere((e) => e.name == post.category);
          if (postCat.group != _selectedGroup) return false;
        } catch (_) {
          return false;
        }
      }
      return true;
    }).toList();

    // Apply the same combined sorting to filtered results
    filtered.sort((a, b) {
       final scoreA = a.createdAt.millisecondsSinceEpoch + ((a.totalReactions + a.commentsCount) * 7200000);
       final scoreB = b.createdAt.millisecondsSinceEpoch + ((b.totalReactions + b.commentsCount) * 7200000);
       return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final postsProvider = context.watch<PostsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;
    final allPosts = postsProvider.posts;
    final posts = _filterPosts(allPosts);
    
    // Restrict clients from posting
    final bool canPost = currentUser != null && currentUser.role != UserRole.client;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // App Bar (Match reference image exactly for RTL)
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              centerTitle: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text(
                locale == 'ar' ? 'المجتمع' : 'Community',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            
            // Search Bar (expandable)
            if (_showSearch)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Smart Search Input with autocomplete
                      SmartSearchField(
                        controller: _searchController,
                        hintText: locale == 'ar' ? 'ابحث في المنشورات...' : 'Search posts...',
                        searchContext: SearchContext.community,
                        accentColor: AppColors.primary,
                        onSearch: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 6),
                      // Category Group Chips
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip(
                              locale == 'ar' ? 'الكل' : 'All',
                              _selectedGroup == null,
                              () {
                                setState(() => _selectedGroup = null);
                                _fetchAds();
                              },
                            ),
                            ...PostCategoryGroup.values.map((group) => _buildCategoryChip(
                              group.getName(locale),
                              _selectedGroup == group,
                              () {
                                setState(() => _selectedGroup = group);
                                _fetchAds();
                              },
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),


          ],
          body: (postsProvider.isLoading && !postsProvider.hasPosts)
              ? ListView.builder(
                  itemCount: 4,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, __) => const PostCardShimmer(),
                )
              : posts.isEmpty && !postsProvider.isLoading
                  ? _searchQuery.isNotEmpty || _selectedGroup != null
                      ? _buildNoSearchResults(context, locale)
                      : _buildEmptyState(context, locale, canPost)
                  : postsProvider.isLoading && posts.isNotEmpty 
                      ? const Column(children: [LinearProgressIndicator(), SizedBox(height: 10)])
                      : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => _isFirstLoad = false); // بعد التحديث اليدوي لا يثبت الإعلان في الأعلى
                        _fetchAds();
                        return postsProvider.fetchPosts(forceRefresh: true);
                      },
                      child: Builder(builder: (context) {
                        final mixedFeed = _buildMixedFeed(posts);
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          // cacheExtent كبير لمنع إعادة تهيئة VideoPlayerController عند التمرير
                          cacheExtent: 800,
                          itemCount: mixedFeed.length,
                          itemBuilder: (context, index) {
                            final item = mixedFeed[index];

                            // ─ عرض إعلان ─ محاط بـ ClipRect لمنع تداخل أنيميشن المنشورات المجاورة
                            if (item is AdModel) {
                              return ClipRect(
                                child: AdWidget(
                                  ad: item,
                                  onTap: () {
                                    _adService.recordClick(item.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => AdDetailsScreen(ad: item)),
                                    );
                                  },
                                ),
                              );
                            }

                            // ─ عرض منشور ─
                            final post = item as PostModel;
                            final postIndex = mixedFeed
                                .sublist(0, index)
                                .whereType<PostModel>()
                                .length;

                            return Column(
                              children: [
                                StaggeredAnimatedWidget(
                                  index: postIndex,
                                  listId: 'posts_feed',
                                  child: PostCard(
                                    post: post,
                                    currentUserId: currentUser?.id ?? '',
                                    locale: locale,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (postIndex == posts.length - 1 && postsProvider.isLoadingMore)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                              ],
                            );
                          },
                        );
                      }),
                    ),
        ),
      ),
      floatingActionButton: canPost
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: FloatingActionButton(
                heroTag: 'create_post_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePostScreen(
                        showInCommunity: true,
                        showInProfile: false,
                      ),
                    ),
                  );
                },
                backgroundColor: AppColors.primary,
                mini: true,
                child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white, size: 22),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(BuildContext context, String locale) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: locale == 'ar' ? 'لا توجد نتائج' : 'No results found',
      subtitle: locale == 'ar' ? 'جرب كلمات بحث مختلفة' : 'Try different search terms',
      actionLabel: locale == 'ar' ? 'مسح البحث' : 'Clear Search',
      onAction: () {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _selectedGroup = null;
        });
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String locale, bool canPost) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateWidget(
      icon: Icons.photo_library_rounded,
      title: l10n.noPosts,
      subtitle: canPost ? l10n.beFirstToShare : l10n.followToSeePosts,
      actionLabel: canPost ? l10n.createPost : null,
      onAction: canPost ? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        );
      } : null,
    );
  }
}
