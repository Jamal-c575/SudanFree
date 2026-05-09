import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../profile/profile_screen.dart';
import '../requests/requests_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/firestore_service.dart';
import '../../services/firestore/ad_service.dart';
import '../../models/ad_model.dart';
import '../../views/widgets/ad_widget.dart';
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
  PostCategory? _selectedCategory;
  bool _showSearch = false;
  Timer? _heartbeatTimer;
  AdModel? _currentAd;
  bool _isLoadingAd = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostsProvider>().fetchPosts();
      context.read<AuthProvider>().fetchPartners();
      _fetchAd();
      // First heartbeat
      _sendHeartbeat();
      // Periodic heartbeat every 15 minutes to keep user online (saving Firestore writes)
      _heartbeatTimer = Timer.periodic(const Duration(minutes: 15), (_) => _sendHeartbeat());
    });
    
    // Infinite Scroll Listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        context.read<PostsProvider>().fetchMorePosts();
      }
    });
  }

  Future<void> _fetchAd() async {
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser != null) {
      final ad = await AdService().getTargetedAd(currentUser);
      if (mounted) {
        setState(() {
          _currentAd = ad;
          _isLoadingAd = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingAd = false);
    }
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
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PostModel> _filterPosts(List<PostModel> posts) {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
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
      if (_selectedCategory != null && post.category != _selectedCategory!.name) {
        return false;
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

    // Show only the user's partners instead of random freelancers/shops
    // Sort: online partners first, then the rest
    final allPartners = authProvider.partners.take(15).toList();
    final featuredUsers = [
      ...allPartners.where((u) => u.isOnline),
      ...allPartners.where((u) => !u.isOnline),
    ];

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
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RequestsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'ar' ? 'الطلبات' : 'Requests',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
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
                      // Category Chips
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip(
                              locale == 'ar' ? 'الكل' : 'All',
                              _selectedCategory == null,
                              () => setState(() => _selectedCategory = null),
                            ),
                            ...PostCategory.values.map((cat) => _buildCategoryChip(
                              cat.getName(locale),
                              _selectedCategory == cat,
                              () => setState(() => _selectedCategory = cat),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Featured Users Bar - Shimmer while loading
            if (featuredUsers.isEmpty && currentUser != null && currentUser.partnerIds.isNotEmpty && !_showSearch)
              SliverToBoxAdapter(
                child: Container(
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 12, top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Shimmer.fromColors(
                          baseColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[800]! : Colors.grey[300]!,
                          highlightColor: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey[700]! : Colors.grey[100]!,
                          child: Column(
                            children: [
                              Container(
                                width: 70, height: 70,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 50, height: 10,
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Featured Users Bar (Match reference image - "Stories")
            if (featuredUsers.isNotEmpty && !_showSearch)
              SliverToBoxAdapter(
                child: Container(
                  height: 110,
                  margin: const EdgeInsets.only(bottom: 12, top: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: featuredUsers.length,
                    itemBuilder: (context, index) {
                      final user = featuredUsers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
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
                                    padding: const EdgeInsets.all(3),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                      backgroundImage: user.profileImageUrl != null
                                          ? CachedNetworkImageProvider(user.profileImageUrl!)
                                          : null,
                                      child: user.profileImageUrl == null
                                          ? Icon(
                                              user.role == UserRole.shop ? Icons.store : Icons.person,
                                              color: AppColors.textSecondary,
                                            )
                                          : null,
                                    ),
                                  ),
                                  // Green dot for online users
                                  if (user.isOnline)
                                    Positioned(
                                      bottom: 3,
                                      right: 3,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
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
                                width: 70,
                                child: Text(
                                  user.name.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 12,
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
                  ? _searchQuery.isNotEmpty || _selectedCategory != null
                      ? _buildNoSearchResults(context, locale)
                      : _buildEmptyState(context, locale, canPost)
                  : postsProvider.isLoading && posts.isNotEmpty 
                      ? const Column(children: [LinearProgressIndicator(), SizedBox(height: 10)])
                      : RefreshIndicator(
                      onRefresh: () async {
                        _fetchAd();
                        return postsProvider.fetchPosts(forceRefresh: true);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        cacheExtent: 250, // Reduced cache extent to save memory
                        itemCount: posts.length + (_currentAd != null && _searchQuery.isEmpty && _selectedCategory == null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == 0 && _currentAd != null && _searchQuery.isEmpty && _selectedCategory == null) {
                            return AdWidget(ad: _currentAd!);
                          }
                          
                          final postIndex = (_currentAd != null && _searchQuery.isEmpty && _selectedCategory == null) ? index - 1 : index;
                          final post = posts[postIndex];

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
                              if (postIndex < posts.length - 1)
                                const SizedBox(height: 8),
                              if (postIndex == posts.length - 1 && postsProvider.isLoadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                            ],
                          );
                        },
                      ),
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
          _selectedCategory = null;
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
