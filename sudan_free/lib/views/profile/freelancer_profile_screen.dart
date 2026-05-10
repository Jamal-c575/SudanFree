import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'create_portfolio_project_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/contact_log_model.dart';
import '../../providers/user_provider.dart';
import '../../models/post_model.dart';
import '../../models/review_model.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';
import '../../services/firestore_service.dart';
import '../posts/create_post_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/cards/post_card.dart';
import '../../widgets/common/linkable_text.dart';
import '../../widgets/common/image_carousel.dart';

import '../../widgets/reviews/review_widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/utils/job_titles_utils.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../core/constants/sudan_locations.dart';
import 'dart:io';
import '../../views/common/image_viewer_screen.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/staggered_animated_widget.dart';
import '../../widgets/common/keep_alive_tab_view.dart';
import '../../widgets/common/verification_badge.dart';
import '../../views/common/report_dialog.dart';
import '../../models/portfolio_project_model.dart';
import '../../core/utils/app_error_handler.dart';

class FreelancerProfileScreen extends StatefulWidget {
  final UserModel user;
  final bool isMe;

  final int initialTabIndex;
  final bool showReviewDialog;

  const FreelancerProfileScreen({
    super.key,
    required this.user,
    required this.isMe, // Passed from parent check (currentUser.id == user.id)
    this.initialTabIndex = 0,
    this.showReviewDialog = false,
  });

  @override
  State<FreelancerProfileScreen> createState() => _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends State<FreelancerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploadingImage = false; // loading state for photo upload

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    
    if (widget.showReviewDialog && !widget.isMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddReviewDialog();
      });
    }

    // Increment profile views if not me
    if (!widget.isMe) {
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      if (currentUserId != null) {
        FirestoreService()
            .incrementProfileViews(widget.user.id, currentUserId)
            .catchError((_) {}); // Non-critical: silently ignore permission errors
      }
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
      body: Stack(
        children: [
          StreamBuilder<UserModel?>(
            stream: FirestoreService().getUserStream(widget.user.id),
            initialData: widget.user,
            builder: (context, snapshot) {
              final user = snapshot.data ?? widget.user;
              
              return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: false,
                  floating: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
                  leading: const BackButton(),
                  actions: [
                    if (widget.isMe) ...[
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
                      IconButton(
                        icon: const Icon(Icons.flag_outlined, color: Colors.white),
                        tooltip: l10n.reportStore,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => ReportDialog(reportedUser: user),
                          );
                        },
                      ),
                    ]
                  ],
                  flexibleSpace: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final double expandedHeight = 200.0;
                      final double collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
                      final double currentHeight = constraints.biggest.height;
                      
                      double progress = (currentHeight - collapsedHeight) / (expandedHeight - collapsedHeight);
                      progress = progress.clamp(0.0, 1.0);
                      
                      final double opacity = progress > 0.4 ? ((progress - 0.4) / 0.6).clamp(0.0, 1.0) : 0.0;
                      final double scale = Curves.easeOut.transform(progress);

                      return Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          // Cover Image
                          GestureDetector(
                            onTap: () => _handleImageTap(user.coverImageUrl, true),
                            child: user.coverImageUrl != null
                                ? Hero(
                                    tag: '${user.id}_cover',
                                    child: CachedNetworkImage(
                                      imageUrl: user.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_,__) => Container(color: Colors.grey[300]),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppColors.primary, AppColors.secondary],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                          ),
                          // Gradient
                          Positioned(
                            bottom: 0, left: 0, right: 0, height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Theme.of(context).scaffoldBackgroundColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Avatar
                          Positioned(
                            bottom: -60,
                            left: 0, right: 0,
                            child: Center(
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: opacity > 0 ? () => _handleImageTap(user.profileImageUrl, false) : null,
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.15),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Hero(
                                            tag: '${user.id}_profile',
                                            child: CircleAvatar(
                                              radius: 80,
                                              backgroundColor: Theme.of(context).cardColor,
                                              backgroundImage: user.profileImageUrl != null
                                                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                                                  : null,
                                              child: user.profileImageUrl == null
                                                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (user.isOnline && !widget.isMe)
                                          Positioned(
                                            bottom: 8, right: 8,
                                            child: Container(
                                              width: 18, height: 18,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
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
                        ],
                      );
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 80), // Space for the overlapping avatar
                        
                        // Name & Skill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                            VerificationBadge(isVerified: user.effectivelyVerified, size: 24),
                          ],
                        ),
                        // All Skills as Chips
                        if (user.skills.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: user.skills.where((s) => s.toLowerCase() != 'other').map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                JobTitlesUtils.getLocalizedTitle(skill, context.read<LocaleProvider>().locale.languageCode),
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            )).toList(),
                          )
                        else
                          Text(
                            JobTitlesUtils.getLocalizedTitle(
                              user.jobTitle ?? 'Freelancer',
                              context.read<LocaleProvider>().locale.languageCode
                            ),
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Stats Row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                               Expanded(child: _buildStatItem(l10n.reviews, '${user.totalStars.round()}', Icons.star, Colors.amber)),
                               Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
                               Expanded(child: _buildStatItem(l10n.completedJobs, '${user.completedJobs}', Icons.work_history, Colors.blue)),
                               Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
                               Expanded(child: _buildStatItem(context.read<LocaleProvider>().isArabic ? 'المشاهدات' : 'Views', '${user.profileViews}', Icons.visibility, Colors.purple)),
                               Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
                               Expanded(child: _buildStatItem(
                                 l10n.location, 
                                 user.state != null 
                                    ? SudanLocations.getStateName(user.state!, context.read<LocaleProvider>().locale.languageCode) 
                                    : (context.read<LocaleProvider>().isArabic ? 'غير محدد' : 'Not set'), 
                                 Icons.location_on, 
                                 Colors.red
                               )),
                               
                               // Partner Button
                               if (!widget.isMe) ...[
                                 Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
                                 Expanded(child: Consumer<AuthProvider>(
                                   builder: (context, auth, _) {
                                     final isPartner = auth.user?.partnerIds.contains(user.id) ?? false;
                                     final isPending = user.pendingPartnerIds.contains(auth.user?.id) || (auth.user?.pendingPartnerIds.contains(user.id) ?? false);
                                     
                                     String titleText = context.read<LocaleProvider>().isArabic ? 'إضافة' : 'Connect';
                                     IconData iconData = Icons.person_add_alt_1;
                                     Color iconColor = Colors.grey;

                                     if (isPartner) {
                                       titleText = context.read<LocaleProvider>().isArabic ? 'متصل' : 'Connected';
                                       iconData = Icons.check_circle;
                                       iconColor = Colors.green;
                                     } else if (isPending) {
                                       titleText = context.read<LocaleProvider>().isArabic ? 'مُعلّق' : 'Pending';
                                       iconData = Icons.schedule;
                                       iconColor = Colors.purple;
                                     }

                                       return _buildStatItem(
                                         context.read<LocaleProvider>().isArabic ? 'زميل' : 'Partner',
                                         titleText,
                                         iconData,
                                         iconColor,
                                         onTap: (isPartner || isPending) ? null : () {
                                           if (auth.user?.role == UserRole.client) {
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text(context.read<LocaleProvider>().isArabic 
                                                     ? 'لا يمكنك إضافة حرفي كزميل بحساب عميل.' 
                                                     : 'Clients cannot add freelancers as partners.'),
                                                 backgroundColor: Colors.red,
                                               ),
                                             );
                                             return;
                                           }
                                           auth.sendPartnerRequest(user.id);
                                           ScaffoldMessenger.of(context).showSnackBar(
                                             SnackBar(
                                               content: Text(context.read<LocaleProvider>().isArabic 
                                                   ? 'تم إرسال طلب الزمالة بنجاح!' 
                                                   : 'Partner request sent successfully!'),
                                               backgroundColor: Colors.green,
                                             ),
                                           );
                                         },
                                       );
                                   },
                                 )),
                               ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),

                        // Bio
                        if (user.bio != null && user.bio!.isNotEmpty)
                          LinkableText(
                            text: user.bio!,
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.5, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.9)),
                          ),

                        const SizedBox(height: 24),
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
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(text: Localizations.localeOf(context).languageCode == 'ar' ? 'المنشورات' : 'Posts'),
                        Tab(text: Localizations.localeOf(context).languageCode == 'ar' ? 'المعرض' : 'Portfolio'),
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
                // Tab 1: Posts (Grid)
                KeepAliveTabView(child: _buildPortfolioGrid()),

                // Tab 2: Professional Portfolio (Detailed)
                KeepAliveTabView(child: _buildProfessionalPortfolio()),
                
                // Tab 3: Reviews (List + Add Button)
                KeepAliveTabView(child: _buildReviewsSection()),
              ],
            ),
          );
        }
      ),
          // Loading overlay while uploading image
          if (_isUploadingImage)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        context.read<LocaleProvider>().isArabic
                            ? 'جاري رفع الصورة...'
                            : 'Uploading image...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.isMe 
          ? ((_tabController.index == 0 || _tabController.index == 1)
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FloatingActionButton(
                    heroTag: 'add_portfolio_fab',
                    onPressed: () {
                      if (_tabController.index == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePortfolioProjectScreen()),
                        );
                      }
                    },
                    backgroundColor: AppColors.primary,
                    mini: true,
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                )
              : null)
          : Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: () => _showContactMenu(context, widget.user),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.support_agent, color: Colors.white),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ar' ? 'تواصل معي' : 'Contact Me',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
    );
  }

  void _showContactMenu(BuildContext context, UserModel freelancer) {
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
                Localizations.localeOf(context).languageCode == 'ar' ? 'تواصل مع الحرفي' : 'Contact Freelancer',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.chat, color: Colors.white)),
                title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'واتساب' : 'WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsApp(freelancer.whatsappNumber ?? freelancer.phoneNumber);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primary, child: const Icon(Icons.call, color: Colors.white)),
                title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'اتصال مباشر' : 'Direct Call'),
                onTap: () {
                  Navigator.pop(ctx);
                  _makePhoneCall(freelancer.phoneNumber);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue, child: const Icon(Icons.handshake, color: Colors.white)),
                title: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إنشاء عقد اتفاق (دردشة)' : 'Create Contract (Chat)'),
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
                      otherUserId: freelancer.id,
                      otherUserName: freelancer.name,
                      otherUserImageUrl: freelancer.profileImageUrl,
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
                    if (mounted) AppErrorHandler.show(context, e, stack, logContext: 'FreelancerProfile.createChat');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets & Methods ---

  Widget _buildStatItem(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: onTap != null ? color : null)), // Highlight value if clickable
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPortfolioGrid() {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<PostModel>>(
      stream: FirestoreService().getUserPosts(widget.user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading posts: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'خطأ في تحميل الأعمال. قد يحتاج النظام لإنشاء فهرس (Index) في قاعدة البيانات.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: LoadingIndicator());
        final portfolioPosts = snapshot.data!.toList();

        // Sort: Pinned first, then by date (descending)
        portfolioPosts.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

          if (portfolioPosts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    widget.isMe ? l10n.addWork : l10n.noWorkDisplayed,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: portfolioPosts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final post = portfolioPosts[index];
              return StaggeredAnimatedWidget(
                index: index,
                listId: 'freelancer_profile_${widget.user.id}',
                child: PostCard(
                  post: post,
                  currentUserId: context.read<AuthProvider>().user?.id ?? '',
                  locale: Localizations.localeOf(context).languageCode,
                  showActions: true,
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
        Text(l10n.reviews, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _buildReviewsList(),
      ],
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<ReviewModel>>(
      stream: FirestoreService().getFreelancerReviews(widget.user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.noReviews, style: const TextStyle(color: Colors.grey)));
        
        return Column(
          children: snapshot.data!.map((review) => ReviewCard(review: review, locale: context.read<LocaleProvider>().locale.languageCode)).toList(),
        );
      },
    );
  }

  void _showAddReviewDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = context.read<AuthProvider>().user;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginToReview)));
      return;
    }

    // التحقق من وجود contactLog قبل السماح بالتقييم
    final hasContact = await FirestoreService().hasContactLog(
      currentUser.id,
      widget.user.id,
    );

    if (!hasContact) {
      if (!mounted) return;
      final isArabic = context.read<LocaleProvider>().isArabic;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(isArabic ? 'يجب التواصل أولاً' : 'Contact First')),
            ],
          ),
          content: Text(
            isArabic
                ? 'يجب التواصل مع الحرفي عبر واتساب أو الاتصال قبل إضافة تقييم. هذا يضمن مصداقية التقييمات.'
                : 'You must contact this freelancer via WhatsApp or call before leaving a review. This ensures review credibility.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _openWhatsApp(widget.user.whatsappNumber ?? widget.user.phoneNumber);
              },
              icon: const Icon(Icons.chat, size: 18),
              label: Text(l10n.openWhatsApp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
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
        onSubmit: (rating, comment, isNegative, isJobCompleted, wouldWorkAgain) async {
          final l10n = AppLocalizations.of(context)!;
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
            await FirestoreService().createReview(review, isJobCompleted: isJobCompleted);
            
            // تحديث contactLog كـ reviewed
            final contactLog = await FirestoreService().getContactLog(currentUser.id, widget.user.id);
            if (contactLog != null) {
              await FirestoreService().markContactAsReviewed(contactLog.id);
            }
            
            if (!mounted) return;
            messenger.showSnackBar(SnackBar(content: Text(l10n.reviewAddedSuccessfully), backgroundColor: AppColors.success));
          } catch (e, stack) {
            if (!mounted) return;
            if (context.mounted) AppErrorHandler.show(context, e, stack, logContext: 'FreelancerProfile.addReview');
          }
        },
      ),
    );
  }

  Future<void> _openWhatsApp(String? number) async {
    if (number == null || number.isEmpty) return;
    
    final l10n = AppLocalizations.of(context)!;

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
          AppErrorHandler.log(e, stack, context: 'FreelancerProfile.whatsappContactLog');
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
        l10n.localeName == 'ar' 
            ? 'مرحباً، أتواصل معك من خلال منصة سودان فري.' 
            : 'Hello, I am contacting you through the Sudan Free platform.'
      );
      final url = 'https://wa.me/$cleaned?text=$message';
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {}
    } finally {
      // Contact complete
    }
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
          AppErrorHandler.log(e, stack, context: 'FreelancerProfile.callContactLog');
        }
      }
      
      final Uri launchUri = Uri(scheme: 'tel', path: number);
      try {
        await launchUrl(launchUri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (_) {}
    } finally {
      // Call complete
    }
  }

  void _openImage(String url, String tag) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => ImageViewerScreen(imageUrl: url, heroTag: tag))
    );
  }

  void _handleImageTap(String? imageUrl, bool isCover) {
    final l10n = AppLocalizations.of(context)!;
    // If not me, just view image (if exists)
    if (!widget.isMe) {
      if (imageUrl != null) _openImage(imageUrl, isCover ? '${widget.user.id}_cover' : '${widget.user.id}_profile');
      return;
    }

    // If me, show options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isCover ? l10n.coverPhoto : l10n.profilePhoto,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            if (imageUrl != null)
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: Text(AppLocalizations.of(context)!.viewImage),
                onTap: () {
                  Navigator.pop(ctx);
                  _openImage(imageUrl, isCover ? '${widget.user.id}_cover' : '${widget.user.id}_profile');
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(AppLocalizations.of(context)!.changeImage),
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
    // prevent multiple taps
    if (_isUploadingImage) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;
    if (!mounted) return;

    // Show loading overlay
    setState(() => _isUploadingImage = true);

    try {
      final file = File(pickedFile.path);
      final url = isCover
          ? await StorageService().uploadImage(file, folder: 'users/${widget.user.id}/cover')
          : await StorageService().uploadProfileImage(widget.user.id, file);

      if (url != null) {
        // Update Firestore
        final updates = isCover 
            ? {'coverImageUrl': url}
            : {'profileImageUrl': url};
        
        await FirestoreService().updateUserProfile(widget.user.id, updates);
        
        // Update ALL User posts and comments with new image if profile image changed
        if (!isCover) {
          await FirestoreService().updateUserProfileImages(widget.user.id, url, null);
        }

        // Force refresh list
        if (mounted) context.read<UserProvider>().fetchFreelancers(forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LocaleProvider>().isArabic 
                    ? 'تم تحديث الصورة بنجاح ✅' 
                    : 'Image updated successfully ✅'
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<LocaleProvider>().isArabic 
                    ? 'فشل رفع الصورة، تحقق من اتصالك بالإنترنت' 
                    : 'Image upload failed, check your internet connection'
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stack) {
      if (mounted) AppErrorHandler.show(context, e, stack, logContext: 'FreelancerProfile.uploadImage');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }
  Widget _buildProfessionalPortfolio() {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    return StreamBuilder<List<PortfolioProjectModel>>(
      stream: FirestoreService().getUserPortfolio(widget.user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading portfolio: ${snapshot.error}');
          // Show empty state for permission errors instead of red error text
          final errorStr = snapshot.error.toString();
          if (errorStr.contains('permission-denied') || errorStr.contains('PERMISSION_DENIED')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    locale == 'ar' ? 'لا توجد مشاريع في المعرض بعد' : 'No portfolio projects yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                locale == 'ar' ? 'خطأ في تحميل المعرض المهني.' : 'Error loading portfolio.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LoadingIndicator());
        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  locale == 'ar' ? 'لا توجد مشاريع في المعرض بعد' : 'No portfolio projects yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return _buildProjectCard(project, locale);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(PortfolioProjectModel project, String locale) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (project.imageUrls.isNotEmpty)
            ImageCarousel(
              imageUrls: project.imageUrls,
              height: MediaQuery.of(context).size.width, // Square size like community posts
              fit: BoxFit.cover,
              enableZoom: true,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (widget.isMe)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteProject(project),
                      ),
                  ],
                ),
                if (project.category != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      project.category!,
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                LinkableText(
                  text: project.description,
                  style: TextStyle(color: Colors.grey[700], height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProjectDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePortfolioProjectScreen(),
      ),
    );
  }

  void _confirmDeleteProject(PortfolioProjectModel project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المشروع'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا المشروع من معرض أعمالك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              FirestoreService().deletePortfolioProject(widget.user.id, project.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
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
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => true;
}
