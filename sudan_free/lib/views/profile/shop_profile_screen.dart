import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_detail_screen.dart';
import '../../widgets/common/linkable_text.dart';

// ignore: unused_import
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/contact_log_model.dart';
import '../../providers/user_provider.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/adaptive_fab_padding.dart';

import 'create_product_screen.dart';
import 'shop_dashboard_screen.dart';
// To show comments/details
import '../auth/profile_setup_screen.dart'; // For editing
import '../../views/common/report_dialog.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../views/common/image_viewer_screen.dart';
import '../../widgets/common/keep_alive_tab_view.dart';
import '../../core/constants/sudan_locations.dart';
import '../../widgets/common/verification_badge.dart';
import '../chat/chat_screen.dart';
import '../../providers/chat_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../models/review_model.dart';
import '../../widgets/reviews/review_widgets.dart';
import '../../core/utils/app_error_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'favorites_screen.dart';
import '../../services/smart_guide_service.dart';

class ShopProfileScreen extends StatefulWidget {
  final UserModel user;
  final bool isMe;
  final int initialTabIndex;
  final bool showReviewDialog;

  const ShopProfileScreen({
    super.key,
    required this.user,
    required this.isMe,
    this.initialTabIndex = 0,
    this.showReviewDialog = false,
  });

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  late Stream<UserModel?> _userStream;
  late Stream<List<PostModel>> _postsStream;
  late Stream<List<ReviewModel>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    
    _userStream = FirestoreService().getUserStream(widget.user.id);
    _postsStream = FirestoreService().getUserPosts(widget.user.id);
    _reviewsStream = FirestoreService().getFreelancerReviews(widget.user.id);

    if (widget.showReviewDialog && !widget.isMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddReviewDialog();
      });
    }

    // Increment profile views if not me
    if (!widget.isMe) {
      final currentUserId =
          Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (currentUserId != null) {
        FirestoreService()
            .incrementProfileViews(widget.user.id, currentUserId)
            .catchError((_) {}); // Non-critical: silently ignore permission errors
      }
      
      SmartGuideService.showMicroTip(
        context,
        messageAr: 'استكشف منتجات المتجر واقرأ آراء العملاء السابقين 🛍️',
        messageEn: 'Explore shop products and read customer reviews 🛍️',
        tipId: 'shop_profile_visit',
        icon: Icons.storefront_rounded,
      );
    } else {
      SmartGuideService.showMicroTip(
        context,
        messageAr: 'أضف منتجات جديدة وتابع إحصائيات متجرك من هنا 📊',
        messageEn: 'Add new products and track your shop stats here 📊',
        tipId: 'shop_owner_visit',
        icon: Icons.dashboard_customize_rounded,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<UserModel?>(
          stream: _userStream,
          initialData: widget.user,
          builder: (context, snapshot) {
            final user = snapshot.data ?? widget.user;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // 1. Store Header
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: false,
                    floating: false,
                    backgroundColor: AppColors.secondary,
                    systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
                    leading: const BackButton(),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover + Gradient (wrapped together so taps reach cover)
                          GestureDetector(
                            onTap: () =>
                                _handleImageTap(user.coverImageUrl, true),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                user.coverImageUrl != null
                                    ? Hero(
                                        tag: '${user.id}_cover',
                                        child: CachedNetworkImage(
                                            imageUrl: user.coverImageUrl!,
                                            fit: BoxFit.cover),
                                      )
                                    : Container(
                                        color: AppColors.secondary
                                            .withValues(alpha: 0.8)),
                                // Gradient overlay (inside GestureDetector so it doesn't block taps)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.8)
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Info
                          Positioned(
                            bottom: 20,
                            left: 16,
                            right: 16,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Logo
                                GestureDetector(
                                  onTap: () => _handleImageTap(
                                      user.profileImageUrl, false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .scaffoldBackgroundColor,
                                          width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 10)
                                      ],
                                    ),
                                    child: Hero(
                                      tag: '${user.id}_profile',
                                      child: CircleAvatar(
                                        radius: 65,
                                        backgroundImage:
                                            user.profileImageUrl != null
                                                ? CachedNetworkImageProvider(
                                                    user.profileImageUrl!)
                                                : null,
                                        backgroundColor:
                                            Theme.of(context).cardColor,
                                        child: user.profileImageUrl == null
                                            ? const Icon(Icons.store,
                                                size: 40,
                                                color: AppColors.secondary)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Text Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 4)
                                              ],
                                            ),
                                          ),
                                          VerificationBadge(isVerified: user.effectivelyVerified, size: 22),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          user.getShopCategoryName('ar'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
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
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.share, color: Colors.white),
                        tooltip: l10n.localeName == 'ar' ? 'مشاركة الملف الشخصي' : 'Share Profile',
                        onPressed: () {
                          final url = 'https://jamall123.github.io/HOME_WEB/sudan-free.html?profileId=${user.id}';
                          final text = l10n.localeName == 'ar' 
                              ? 'تفضل بزيارة متجر ${user.name} على تطبيق سودان فري:\n$url' 
                              : 'Check out ${user.name}\'s shop on SudanFree:\n$url';
                          Share.share(text);
                        },
                      ),
                      // OWNER ACTIONS: Edit & Settings
                      if (widget.isMe) ...[
                        IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.white),
                          tooltip: l10n.localeName == 'ar' ? 'مفضلاتي' : 'Favorites',
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const FavoritesScreen())),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: l10n.editStore,
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ProfileSetupScreen(existingUser: user))),
                        ),
                      ] else ...[
                        // VISITOR ACTIONS: Report
                        IconButton(
                          icon: const Icon(Icons.flag_outlined,
                              color: Colors.white),
                          tooltip: l10n.reportStore,
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (_) =>
                                    ReportDialog(reportedUser: user));
                          },
                        ),
                      ]
                    ],
                  ),

                  // 2. Action Bar
                  SliverToBoxAdapter(
                    child: Container(
                      color: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: widget.isMe
                           ? // Owner View: Stats Cards + Add Product Button
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 SizedBox(
                                   width: double.infinity,
                                   height: 48,
                                   child: ElevatedButton.icon(
                                     onPressed: () {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(builder: (_) => ShopDashboardScreen(shop: widget.user)),
                                       );
                                     },
                                     icon: const Icon(Icons.dashboard_rounded),
                                     label: Text(
                                       l10n.localeName == 'ar' ? 'لوحة التحكم' : 'Dashboard',
                                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                     ),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: Colors.purple.shade600,
                                       foregroundColor: Colors.white,
                                       elevation: 0,
                                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                     ),
                                   ),
                                 ),
                               ],
                             )
                          : // Visitor View: Contact Buttons
                              Column(
                                children: [
                                  Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildContactButton(
                                        Icons.info_outline,
                                        l10n.details,
                                        Colors.grey,
                                        () => _showShopDetailsDialog(context)),
                                    if (!widget.isMe) ...[
                                      Container(width: 1, height: 24, color: Colors.grey[300]),
                                      // Rating chip (clickable → reviews tab)
                                      GestureDetector(
                                        onTap: () => _tabController.animateTo(1),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                              const SizedBox(width: 2),
                                              Text(
                                                widget.user.rating > 0 ? widget.user.rating.toStringAsFixed(1) : '--',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ]),
                                            Text(
                                              l10n.localeName == 'ar' ? 'تقييم' : 'Rating',
                                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 24, color: Colors.grey[300]),
                                      // Followers Count
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${widget.user.followers.length}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            l10n.localeName == 'ar' ? 'متابع' : 'Followers',
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      Container(width: 1, height: 24, color: Colors.grey[300]),
                                      Consumer<AuthProvider>(
                                        builder: (context, auth, _) {
                                          final isFollowing = widget.user.followers.contains(auth.user?.id);
                                          return _buildContactButton(
                                            isFollowing ? Icons.check : Icons.person_add_alt_1,
                                            isFollowing ? (l10n.localeName == 'ar' ? 'أُتابع' : 'Following') : (l10n.localeName == 'ar' ? 'متابعة' : 'Follow'),
                                            isFollowing ? Colors.green : AppColors.primary,
                                            () async {
                                              if (auth.user == null) return;
                                              try {
                                                await FirestoreService().toggleFollow(auth.user!.id, widget.user.id, isFollowing);
                                                setState(() {
                                                  if (isFollowing) {
                                                    widget.user.followers.remove(auth.user!.id);
                                                  } else {
                                                    widget.user.followers.add(auth.user!.id);
                                                  }
                                                });
                                              } catch (_) {}
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                      ),
                    ),

                  // 3. Tab Bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      topPadding: MediaQuery.of(context).padding.top,
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.secondary,
                        labelColor: AppColors.secondary,
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: l10n.products),
                          Tab(text: l10n.reviews),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  KeepAliveTabView(child: _buildProductsGrid()),
                  KeepAliveTabView(child: _buildReviewsSection()),
                ],
              ),
            );
          }),
      floatingActionButton: widget.isMe 
        ? AdaptiveFabPadding(
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProductScreen()),
              ),
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_box_outlined, size: 26),
            ),
          )
        : (widget.user.role == UserRole.shop || widget.user.role == UserRole.techService || widget.user.role == UserRole.privateService) 
          ? AdaptiveFabPadding(
              child: FloatingActionButton.extended(
                onPressed: () => _showContactMenu(context, widget.user),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ar' ? 'تواصل معنا' : 'Contact Us',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ) 
          : null,
    );
  }

  void _showContactMenu(BuildContext context, UserModel shopUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Localizations.localeOf(context).languageCode == 'ar' ? 'تواصل مع المتجر' : 'Contact Shop',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.chat, color: Colors.white)),
                title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'واتساب' : 'WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsApp(shopUser.whatsappNumber ?? shopUser.phoneNumber);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary, child: const Icon(Icons.call, color: Colors.white)),
                title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'اتصال مباشر' : 'Direct Call'),
                onTap: () {
                  Navigator.pop(ctx);
                  _makePhoneCall(shopUser.phoneNumber);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue, child: const Icon(Icons.handshake, color: Colors.white)),
                title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إنشاء اتفاق (دردشة)' : 'Create Agreement (Chat)'),
                onTap: () async {
                  final authProvider = context.read<AuthProvider>();
                  final currentUser = authProvider.user;
                  if (currentUser == null) return;
                  
                  // Capture before async gap
                  final chatProvider = context.read<ChatProvider>();
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final locale = Localizations.localeOf(context).languageCode;

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final chat = await chatProvider.getOrCreateChat(
                      currentUserId: currentUser.id,
                      currentUserName: currentUser.name,
                      currentUserImageUrl: currentUser.profileImageUrl,
                      otherUserId: shopUser.id,
                      otherUserName: shopUser.name,
                      otherUserImageUrl: shopUser.profileImageUrl,
                    );
                    
                    // Pop loading dialog
                    navigator.pop();
                    // Pop bottom sheet
                    if (ctx.mounted) Navigator.pop(ctx);

                    if (chat != null) {
                      navigator.push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chat: chat, autoOpenContractDialog: true),
                        ),
                      );
                    } else {
                      final errorMsg = chatProvider.errorMessage ?? (locale == 'ar' ? 'حدث خطأ أثناء إنشاء المحادثة' : 'Error creating chat');
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                      );
                    }
                  } catch (e, stack) {
                    navigator.pop();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) AppErrorHandler.show(context, e, stack, logContext: 'ShopProfile.createChat');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<PostModel>>(
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = (snapshot.data ?? []).where((p) => p.showInProfile).toList();

        // Sort: Pinned first, then by date (descending)
        products.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  widget.isMe ? l10n.emptyStoreOwner : l10n.emptyStoreVisitor,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final imageUrl = product.allImageUrls.isNotEmpty ? product.allImageUrls.first : null;
            
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                          if (widget.isMe)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.remove_red_eye, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product.viewsCount}',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LinkableText(
                              text: product.caption ?? l10n.noData,
                              maxLines: 2,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (product.price != null)
                              Text(
                                '${product.price} SDG',
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsSection() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.reviews,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (!widget.isMe)
              TextButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.rate_review, size: 18),
                label: Text(l10n.addReview),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewsStream, // Reusing freelancer reviews method for shops
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)!.noReviews,
                  style: const TextStyle(color: Colors.grey)));
        }

        return Column(
          children: snapshot.data!
              .map((review) => ReviewCard(
                  review: review,
                  locale: context.read<LocaleProvider>().locale.languageCode))
              .toList(),
        );
      },
    );
  }

  void _showAddReviewDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.loginToReview)));
      return;
    }

    // التحقق من وجود اتفاق مكتمل قبل السماح بالتقييم
    final hasCompletedJob = await FirestoreService().hasCompletedJob(
      currentUser.id,
      widget.user.id,
    );

    if (!hasCompletedJob) {
      if (!mounted) return;
      final isArabic = context.read<LocaleProvider>().isArabic;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(isArabic ? 'يجب إكمال اتفاق أولاً' : 'Complete an Agreement First')),
            ],
          ),
          content: Text(
            isArabic
                ? 'يجب أن يكون هناك اتفاق مكتمل بينك وبين المتجر قبل إضافة تقييم. هذا يضمن مصداقية التقييمات.'
                : 'You must have a completed agreement with this shop before leaving a review. This ensures review credibility.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AddReviewDialog(
        freelancerId: widget.user.id,
        targetName: widget.user.name,
        targetImageUrl: widget.user.profileImageUrl,
        isShop: true,
        onSubmit: (rating, comment, isNegative, isJobCompleted,
            wouldWorkAgain) async {
          final messenger = ScaffoldMessenger.of(this.context);

          final review = ReviewModel(
            id: '',
            freelancerId: widget.user.id,
            reviewerId: currentUser.id,
            reviewerName: currentUser.name,
            reviewerImageUrl: currentUser.profileImageUrl,
            rating: rating,
            comment: comment,
            isNegative: isNegative,
            wouldWorkAgain: wouldWorkAgain,
            createdAt: DateTime.now(),
          );

          try {
            await FirestoreService()
                .createReview(review, isJobCompleted: false);
            
            // Log review successfully added
            debugPrint('Review added successfully for job completion check');
            
            messenger.showSnackBar(SnackBar(
                content: Text(l10n.reviewAddedSuccessfully),
                backgroundColor: AppColors.success));
          } catch (e, stack) {
            if (context.mounted) AppErrorHandler.show(context, e, stack, logContext: 'ShopProfile.addReview');
          }
        },
      ),
    );
  }

  Widget _buildContactButton(
      IconData icon, String label, Color color, VoidCallback? onTap, {bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: Column(
          children: [
            isLoading 
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                : Icon(icon, color: color, size: 24),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String? number) async {
    if (number == null || number.isEmpty) return;


    final isArabic = context.read<LocaleProvider>().isArabic;

    try {
      // تسجيل contactLog قبل فتح واتساب
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser != null && currentUser.id != widget.user.id) {
        try {
          final log = ContactLogModel(
            id: '',
            contacterId: currentUser.id,
            contacterName: currentUser.name,
            freelancerId: widget.user.id,
            freelancerName: widget.user.name,
            contactType: 'whatsapp',
            createdAt: DateTime.now(),
          );
          await FirestoreService().createContactLog(log);
        } catch (e, stack) {
          AppErrorHandler.log(e, stack, context: 'ShopProfile.whatsappContactLog');
        }
      }

      String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleaned.startsWith('00')) {
        cleaned = cleaned.substring(2);
      } else if (cleaned.startsWith('+')) {
        cleaned = cleaned.substring(1);
      } else if (cleaned.startsWith('0')) {
        cleaned = '249${cleaned.substring(1)}';
      } else if (!cleaned.startsWith('249') && cleaned.length == 9) {
        cleaned = '249$cleaned';
      }

      final message = Uri.encodeComponent(
        isArabic 
            ? 'مرحباً، أتواصل معك من خلال منصة سودان فري.' 
            : 'Hello, I am contacting you through the Sudan Free platform.'
      );
      final url = 'https://wa.me/$cleaned?text=$message';
      final uri = Uri.parse(url);

      try {
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {}
    } catch (e, stack) {
      AppErrorHandler.log(e, stack, context: 'ShopProfile.launchWhatsApp');
    } finally {
    }
  }

  void _showShopDetailsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.read<LocaleProvider>().locale.languageCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.store, color: AppColors.secondary),
            const SizedBox(width: 8),
            Text(
              widget.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(
                Icons.category_outlined,
                l10n.storeCategory,
                widget.user.getShopCategoryName(locale),
              ),
              const Divider(height: 24),
              _buildDetailItem(
                Icons.info_outline,
                l10n.aboutStore,
                widget.user.bio ?? l10n.noData,
              ),
              const Divider(height: 24),
              _buildDetailItem(
                Icons.location_on_outlined,
                l10n.location,
                '${widget.user.locality != null ? "${SudanLocations.getLocalityName(widget.user.locality!, locale)} - " : ''}${widget.user.state != null ? SudanLocations.getStateName(widget.user.state!, locale) : ''}',
              ),
              const Divider(height: 24),
              _buildDetailItem(
                Icons.access_time,
                l10n.workingHours,
                (widget.user.openingHours != null &&
                        widget.user.closingHours != null)
                    ? '${l10n.from} ${widget.user.openingHours} ${l10n.to} ${widget.user.closingHours}'
                    : l10n.undefined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 36),
            child: LinkableText(
              text: value,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String? number) async {
    if (number == null) return;
    


    try {
      // تسجيل contactLog قبل الاتصال
      final currentUser = context.read<AuthProvider>().user;
      if (currentUser != null && currentUser.id != widget.user.id) {
        try {
          final log = ContactLogModel(
            id: '',
            contacterId: currentUser.id,
            contacterName: currentUser.name,
            freelancerId: widget.user.id,
            freelancerName: widget.user.name,
            contactType: 'call',
            createdAt: DateTime.now(),
          );
          await FirestoreService().createContactLog(log);
        } catch (e, stack) {
          AppErrorHandler.log(e, stack, context: 'ShopProfile.callContactLog');
        }
      }

      final Uri launchUri = Uri(scheme: 'tel', path: number);
      try {
        await launchUrl(launchUri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {}
    } catch (e, stack) {
      AppErrorHandler.log(e, stack, context: 'ShopProfile.launchCall');
    } finally {
    }
  }

  void _openImage(String url, String tag) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ImageViewerScreen(imageUrl: url, heroTag: tag)));
  }

  void _handleImageTap(String? imageUrl, bool isCover) {
    final l10n = AppLocalizations.of(context)!;
    // If not me, just view image (if exists)
    if (!widget.isMe) {
      if (imageUrl != null) {
        _openImage(imageUrl,
            isCover ? '${widget.user.id}_cover' : '${widget.user.id}_profile');
      }
      return;
    }

    // If me, show options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isCover ? l10n.coverPhoto : l10n.storePhoto,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            if (imageUrl != null)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(l10n.viewImage),
                onTap: () {
                  Navigator.pop(ctx);
                  _openImage(
                      imageUrl,
                      isCover
                          ? '${widget.user.id}_cover'
                          : '${widget.user.id}_profile');
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.changeImage),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(isCover: isCover);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage({required bool isCover}) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n.uploadingImage),
          duration: const Duration(seconds: 2)),
    );

    final file = File(pickedFile.path);
    final storage = StorageService();

    // Upload
    final url = isCover
        ? await storage.uploadImage(file, folder: 'users/${widget.user.id}/cover')
        : await storage.uploadProfileImage(widget.user.id, file);

    if (url != null) {
      // Update Firestore
      final updates =
          isCover ? {'coverImageUrl': url} : {'profileImageUrl': url};

      await FirestoreService().updateUserProfile(widget.user.id, updates);

      // Update ALL User posts and comments with new image if profile image changed
      if (!isCover) {
        await FirestoreService()
            .updateUserProfileImages(widget.user.id, url, null);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.imageUpdated),
            backgroundColor: AppColors.success),
      );

      // Force refresh shops data in provider
      context
          .read<UserProvider>()
          .fetchShops(category: null, forceRefresh: true);

      // Reload screen
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ShopProfileScreen(
                  user: widget.user.copyWith(
                      coverImageUrl: isCover ? url : widget.user.coverImageUrl,
                      profileImageUrl:
                          !isCover ? url : widget.user.profileImageUrl),
                  isMe: true)));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.imageUploadFailed), backgroundColor: Colors.red),
      );
    }
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final double topPadding;
  _SliverTabBarDelegate(this._tabBar, {this.topPadding = 0});

  @override
  double get minExtent => _tabBar.preferredSize.height + topPadding;
  @override
  double get maxExtent => _tabBar.preferredSize.height + topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPadding),
          _tabBar,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return true;
  }
}
