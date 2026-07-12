import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/squad_model.dart';
import '../../providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import 'profile_screen.dart'; // To navigate to individual members
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/chat_provider.dart';
import '../chat/chat_screen.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../../core/constants/sudan_locations.dart';

import '../../models/portfolio_project_model.dart';
import 'portfolio_project_detail_screen.dart';
import 'squad_dashboard_screen.dart';
import '../../widgets/common/glass_container.dart';
import '../../../core/utils/job_titles_utils.dart';

import "package:sudan_free/providers/favorites_provider.dart";
import 'package:sudan_free/l10n/generated/app_localizations.dart';

class SquadProfileScreen extends StatefulWidget {
  final SquadModel squad;

  const SquadProfileScreen({super.key, required this.squad});

  @override
  State<SquadProfileScreen> createState() => _SquadProfileScreenState();
}

class _SquadProfileScreenState extends State<SquadProfileScreen>
    with SingleTickerProviderStateMixin {
  // Mock data for members since we don't have a direct user list yet
  // In a real scenario, we would fetch UserModels using widget.squad.memberIds

  late TabController _tabController;
  late Stream<List<PortfolioProjectModel>> _portfolioStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _portfolioStream = FirestoreService().getUserPortfolio(widget.squad.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isAr = locale == 'ar';

    final currentUser = context.read<AuthProvider>().user;
    final isLeader = widget.squad.leaderId == currentUser?.id;
    final isMember = widget.squad.memberIds.contains(currentUser?.id);
    final shouldShowHireButton = !isLeader && !isMember && currentUser != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // 1. App Bar & Cover Image
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              actions: [
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final currentUser = auth.user;
                    if (currentUser == null) return const SizedBox.shrink();

                    final isFavorite =
                        currentUser.favoriteSquadIds.contains(widget.squad.id);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favorite button for non-members
                        if (!isLeader && !isMember)
                          IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                            ),
                            tooltip:
                                AppLocalizations.of(context)!.addToFavorites,
                            onPressed: () {
                              context.read<FavoritesProvider>().toggleFavoriteSquad(widget.squad.id);
                            },
                          ),

                        // Dashboard icon for leader
                        if (isLeader)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.dashboard,
                                  color: Colors.white),
                              tooltip: AppLocalizations.of(context)!.squadDashboard,
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => SquadDashboardScreen(
                                            squad: widget.squad)));
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.squad.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Placeholder for cover or actual image
                    widget.squad.squadImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.squad.squadImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(Icons.engineering,
                                size: 100, color: Colors.white24),
                          ),
                    // Dark overlay for text visibility
                    Container(color: Colors.black.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),

            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                topPadding: MediaQuery.of(context).padding.top,
                TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: const EdgeInsets.all(2),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  splashBorderRadius: BorderRadius.circular(20),
                  tabs: [
                    Tab(
                        height: 28,
                        text: AppLocalizations.of(context)!.squadInfo),
                    Tab(height: 28, text: AppLocalizations.of(context)!.portfolio),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Squad Info
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                            Icons.group,
                            widget.squad.memberIds.length.toString(),
                            AppLocalizations.of(context)!.members),
                        _buildStatColumn(
                            Icons.star,
                            widget.squad.rating.toStringAsFixed(1),
                            AppLocalizations.of(context)!.rating),
                        _buildStatColumn(
                            Icons.task_alt,
                            widget.squad.completedJobs.toString(),
                            AppLocalizations.of(context)!.jobs),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Location and Availability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Location
                        if (widget.squad.state != null)
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${SudanLocations.getStateName(widget.squad.state!, locale)}${widget.squad.locality != null ? " - ${SudanLocations.getLocalityName(widget.squad.locality!, locale)}" : ""}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Squad Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category,
                              size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            widget.squad.category.getName(locale),
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Squad Bio/Description
                    Text(
                      AppLocalizations.of(context)!.aboutSquad,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.squad.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Combined Skills
                    Text(
                      AppLocalizations.of(context)!.servicesSkills,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (widget.squad.combinedSkills.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.squad.combinedSkills.map((skill) {
                          return Chip(
                            label: Text(JobTitlesUtils.getLocalizedTitle(skill, locale),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.sudanGold,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      )
                    else
                      FutureBuilder<List<UserModel>>(
                        future: FirestoreService()
                            .getUsersByIds(widget.squad.memberIds),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final users = snapshot.data ?? [];
                          // استخراج مهارات جميع الأعضاء وحذف المكرر
                          final memberSkills = users
                              .expand((u) => u.skills)
                              .toSet()
                              .toList();

                          if (memberSkills.isEmpty) {
                            return Text(
                                AppLocalizations.of(context)!.noSkillsDefinedYet,
                                style: TextStyle(color: Colors.grey[600]));
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: memberSkills.map((skill) {
                              return Chip(
                                label: Text(JobTitlesUtils.getLocalizedTitle(skill, locale),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                backgroundColor: AppColors.primary, // لون مختلف للمهارات المستنتجة تلقائيا
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                side: BorderSide.none,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    const SizedBox(height: 32),

                    // Team Members Section
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded,
                            color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.teamMembers,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Horizontal list of members
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.squad.memberIds.length,
                        itemBuilder: (context, index) {
                          final memberId = widget.squad.memberIds[index];
                          final isLeaderOfSquad =
                              memberId == widget.squad.leaderId;
                          final currentUser = context.read<AuthProvider>().user;
                          final isViewerLeader =
                              widget.squad.leaderId == currentUser?.id;

                          return GestureDetector(
                            onLongPress: (isViewerLeader && !isLeaderOfSquad)
                                ? () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(AppLocalizations.of(context)!.removeMember),
                                        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo1),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: Text(
                                                  AppLocalizations.of(context)!.cancel)),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            child: Text(AppLocalizations.of(context)!.remove,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      await FirebaseFirestore.instance
                                          .collection('squads')
                                          .doc(widget.squad.id)
                                          .update({
                                        'memberIds':
                                            FieldValue.arrayRemove([memberId])
                                      });

                                      // Send notification to the removed member
                                      await FirebaseFirestore.instance.collection('notifications').add({
                                        'userId': memberId,
                                        'title': isAr ? 'تم إزالتك من المجموعة' : 'Removed from Group',
                                        'message': isAr ? 'تم إزالتك من المجموعة ${widget.squad.name} بواسطة القائد.' : 'You have been removed from the group ${widget.squad.name} by the leader.',
                                        'type': 'squad_kick',
                                        'relatedId': widget.squad.id,
                                        'isRead': false,
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(AppLocalizations.of(context)!.memberRemovedSuccessfully),
                                                backgroundColor: Colors.green));
                                      }
                                    }
                                  }
                                : null,
                            child: _buildMemberCard(
                                memberId, isLeaderOfSquad, isAr),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Tab 2: Portfolio
            _buildProfessionalPortfolio(),
          ],
        ),
      ),

      // Bottom Action Bar
      bottomNavigationBar: shouldShowHireButton
          ? GlassContainer(
              blur: 15,
              opacity:
                  Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.8,
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.handshake),
                  label: Text(
                    AppLocalizations.of(context)!.hireSquad,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final currentUser = context.read<AuthProvider>().user;
                    if (currentUser == null) return;

                    if (widget.squad.leaderId == currentUser.id) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context)!.youAreTheLeaderOfThis)));
                      return;
                    }

                    final chatProv = context.read<ChatProvider>();
                    // Get or create chat with the squad leader
                    final chat = await chatProv.getOrCreateChat(
                      currentUserId: currentUser.id,
                      currentUserName: currentUser.name,
                      currentUserImageUrl: currentUser.profileImageUrl,
                      otherUserId: widget.squad.leaderId,
                      otherUserName: widget
                          .squad.name, // Display squad name or leader name
                    );

                    if (chat != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chat: chat,
                            autoOpenContractDialog: true,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildMemberCard(String userId, bool isLeader, bool isAr) {
    return FutureBuilder<UserModel?>(
      future: FirestoreService().getUser(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12, left: 12),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(
                        color:
                            isLeader ? AppColors.sudanGold : Colors.transparent,
                        width: 3),
                  ),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ],
            ),
          );
        }

        final user = snapshot.data!;

        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: userId)));
          },
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12, left: 12),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        border: Border.all(
                            color: isLeader
                                ? AppColors.sudanGold
                                : Colors.transparent,
                            width: 3),
                      ),
                      child: ClipOval(
                        child: user.profileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user.profileImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Icon(Icons.person,
                                size: 40, color: Colors.grey[600]),
                      ),
                    ),
                    if (isLeader)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.sudanGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star,
                              size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isLeader
                      ? (AppLocalizations.of(context)!.leader)
                      : (AppLocalizations.of(context)!.member),
                  style: TextStyle(
                    color: isLeader ? AppColors.sudanGold : Colors.grey[700],
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfessionalPortfolio() {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    return StreamBuilder<List<PortfolioProjectModel>>(
      stream: _portfolioStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading portfolio: ${snapshot.error}');
          final errorStr = snapshot.error.toString();
          if (errorStr.contains('permission-denied') ||
              errorStr.contains('PERMISSION_DENIED')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noPortfolioProjectsYet,
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
                AppLocalizations.of(context)!.errorLoadingPortfolio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.noPortfolioProjectsYet,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PortfolioProjectDetailScreen(
              project: project,
              providerName: widget.squad.name,
              providerImageUrl: widget.squad.squadImageUrl,
            ),
          ),
        );
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 24),
        blur: 15,
        opacity: isDark ? 0.3 : 0.6,
        borderRadius: BorderRadius.circular(20),
        color: theme.cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.imageUrls.isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: project.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: Colors.grey.withValues(alpha: 0.1),
                          child:
                              const Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey)),
                    ),
                  ),
                  if (project.imageUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text('${project.imageUrls.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 14, height: 1.5),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar, {required this.topPadding});

  @override
  double get minExtent => 40 + topPadding;
  @override
  double get maxExtent => 40 + topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: topPadding + 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 32,
              child: GlassContainer(
                blur: 20,
                opacity: isDark ? 0.3 : 0.9,
                color: isDark ? Colors.black45 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: tabBar,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar || topPadding != oldDelegate.topPadding;
  }
}
