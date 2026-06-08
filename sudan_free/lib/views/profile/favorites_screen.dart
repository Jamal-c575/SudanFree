import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import '../posts/post_details_screen.dart';
import '../../models/post_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/smart_guide_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore/user_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String? _mySquadId;

  @override
  void initState() {
    super.initState();
    _checkSquadLeaderStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartGuideService.showMicroTip(
        context,
        messageAr: 'هنا تجد كل ما قمت بحفظه للرجوع إليه لاحقاً 🔖',
        messageEn: 'Here you find everything you saved for later 🔖',
        tipId: 'favorites_tip',
        icon: Icons.favorite_rounded,
      );
    });
  }

  Future<void> _checkSquadLeaderStatus() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      try {
        final snap = await FirebaseFirestore.instance.collection('squads').where('leaderId', isEqualTo: user.id).limit(1).get();
        if (snap.docs.isNotEmpty && mounted) {
          setState(() {
            _mySquadId = snap.docs.first.id;
          });
        }
      } catch (e) {
        debugPrint('Error fetching squad leader status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final user = context.watch<AuthProvider>().user;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(locale == 'ar' ? 'المفضلة' : 'Favorites')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isFreelancer = user.role == UserRole.freelancer || user.role == UserRole.techService || user.role == UserRole.privateService;
    final title = locale == 'ar' ? (!isFreelancer ? 'مفضلاتي' : 'الزملاء والمفضلة') : (!isFreelancer ? 'My Favorites' : 'Partners & Favorites');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            isScrollable: true,
            tabs: [
              Tab(text: locale == 'ar' ? 'الزملاء' : 'Partners'),
              Tab(text: locale == 'ar' ? 'الحسابات المحفوظة' : 'Saved Accounts'),
              Tab(text: locale == 'ar' ? 'المنشورات المحفوظة' : 'Saved Posts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersList(context, user, user.partnerIds, locale, isPartnerList: true),
            _buildUsersList(context, user, user.favoriteUserIds, locale, isPartnerList: false),
            _buildProductsTab(context, user, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context, UserModel user, List<String> userIds, String locale, {required bool isPartnerList}) {
    if (userIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPartnerList ? Icons.group_off : Icons.favorite_border, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              locale == 'ar' 
                  ? (isPartnerList ? 'لا يوجد زملاء حالياً' : 'لا توجد حسابات مفضلة بعد') 
                  : (isPartnerList ? 'No partners yet' : 'No favorite accounts yet'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: FirestoreService().getUsersByIds(userIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(locale == 'ar' ? 'حدث خطأ' : 'An error occurred'));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) return const SizedBox.shrink();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final targetUser = users[index];
            final isFavorite = user.favoriteUserIds.contains(targetUser.id);
            final isPartner = user.partnerIds.contains(targetUser.id);
            
            return Card(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: targetUser.id))),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: targetUser.profileImageUrl != null ? NetworkImage(targetUser.profileImageUrl!) : null,
                  child: targetUser.profileImageUrl == null ? Icon(targetUser.role == UserRole.shop ? Icons.store : Icons.person, color: AppColors.primary) : null,
                ),
                title: Text(targetUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text(targetUser.jobTitle ?? (locale == 'ar' ? 'حساب في سودان فري' : 'SudanFree Account'), style: TextStyle(color: Colors.grey[600])),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isPartnerList)
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          context.read<AuthProvider>().toggleFavoriteUser(targetUser.id);
                          setState(() {});
                        },
                      ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (val) => _handleMenuAction(val, targetUser, user, locale),
                      itemBuilder: (context) => [
                        if (isPartner)
                          PopupMenuItem(
                            value: 'remove_partner',
                            child: Row(children: [const Icon(Icons.person_remove, color: Colors.red, size: 20), const SizedBox(width: 8), Text(locale == 'ar' ? 'إلغاء الزمالة' : 'Remove Partner', style: const TextStyle(color: Colors.red))]),
                          ),
                        PopupMenuItem(
                          value: 'vouch',
                          child: Row(children: [const Icon(Icons.verified, color: AppColors.sudanGold, size: 20), const SizedBox(width: 8), Text(locale == 'ar' ? 'تزكية الحرفي' : 'Recommend Pro')]),
                        ),
                        if (_mySquadId != null && user.role != UserRole.client && user.role != UserRole.shop && targetUser.role != UserRole.client && targetUser.role != UserRole.shop)
                          PopupMenuItem(
                            value: 'invite_squad',
                            child: Row(children: [const Icon(Icons.groups, color: AppColors.primary, size: 20), const SizedBox(width: 8), Text(locale == 'ar' ? 'دعوة للمجموعة' : 'Invite to Squad')]),
                          ),
                        if (user.masterId == targetUser.id || user.apprenticesIds.contains(targetUser.id))
                          PopupMenuItem(
                            value: 'cancel_apprenticeship',
                            child: Row(children: [const Icon(Icons.handshake_rounded, color: Colors.red, size: 20), const SizedBox(width: 8), Text(locale == 'ar' ? 'إلغاء التتلمذ' : 'Cancel Apprenticeship', style: const TextStyle(color: Colors.red))]),
                          )
                        else if (user.masterId == null && user.role != UserRole.shop && user.role != UserRole.client && targetUser.role != UserRole.shop && targetUser.role != UserRole.client) // Cannot request if I am already an apprentice, or if either is shop/client
                          PopupMenuItem(
                            value: 'request_apprenticeship',
                            child: Row(children: [const Icon(Icons.engineering, color: Colors.teal, size: 20), const SizedBox(width: 8), Text(locale == 'ar' ? 'طلب تتلمذ' : 'Apprenticeship Request')]),
                          ),
                      ],
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

  Future<void> _handleMenuAction(String action, UserModel targetUser, UserModel currentUser, String locale) async {
    final isAr = locale == 'ar';
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (action == 'remove_partner') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'إلغاء الزمالة' : 'Remove Partner'),
          content: Text(isAr ? 'هل أنت متأكد من إلغاء زمالة ${targetUser.name}؟' : 'Are you sure you want to remove ${targetUser.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'تراجع' : 'Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? 'حذف' : 'Remove', style: const TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm == true) {
        await context.read<AuthProvider>().handlePartnerRequest(targetUser.id, false);
        if (!mounted) return;
        context.read<AuthProvider>().fetchPartners(forceRefresh: true);
        setState(() {});
      }
    } else if (action == 'vouch') {
      try {
        await UserFirestoreService().vouchForUser(targetUser.id, currentUser);
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'تم إرسال التزكية بنجاح!' : 'Recommendation sent successfully!'), backgroundColor: Colors.green));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'حدث خطأ أثناء التزكية، قد تكون زكيته مسبقاً.' : 'Error sending recommendation, you may have already vouched.'), backgroundColor: Colors.red));
      }
    } else if (action == 'invite_squad') {
      if (_mySquadId == null) return;
      
      try {
        // Check if user is already in a squad
        final isLeaderSnap = await FirebaseFirestore.instance.collection('squads').where('leaderId', isEqualTo: targetUser.id).get();
        final isMemberSnap = await FirebaseFirestore.instance.collection('squads').where('memberIds', arrayContains: targetUser.id).get();
        
        if (isLeaderSnap.docs.isNotEmpty || isMemberSnap.docs.isNotEmpty) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'هذا المستخدم منضم لمجموعة بالفعل ولا يمكنه الدخول في مجموعة أخرى.' : 'This user is already in a squad and cannot join another.'), backgroundColor: Colors.red));
          return;
        }
        
        // Send invite
        await FirebaseFirestore.instance.collection('users').doc(targetUser.id).update({
          'pendingSquadInvites': FieldValue.arrayUnion([_mySquadId])
        });
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'تم إرسال دعوة المجموعة بنجاح!' : 'Squad invite sent successfully!'), backgroundColor: Colors.green));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'حدث خطأ أثناء إرسال الدعوة' : 'Error sending invite'), backgroundColor: Colors.red));
      }
    } else if (action == 'request_apprenticeship') {
      try {
        await UserFirestoreService().sendApprenticeshipRequest(currentUser.id, targetUser.id);
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'تم إرسال طلب التتلمذ بنجاح!' : 'Apprenticeship request sent!'), backgroundColor: Colors.green));
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'حدث خطأ أثناء إرسال الطلب' : 'Error sending request'), backgroundColor: Colors.red));
      }
    } else if (action == 'cancel_apprenticeship') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'إلغاء التتلمذ' : 'Cancel Apprenticeship'),
          content: Text(isAr ? 'هل أنت متأكد من فك الارتباط؟ إذا كنت الصبي، سيتم إرسال طلب للموافقة.' : 'Are you sure you want to cancel? If you are the apprentice, a request will be sent for approval.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'تراجع' : 'Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? 'تأكيد' : 'Confirm', style: const TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (confirm == true) {
        try {
          if (currentUser.apprenticesIds.contains(targetUser.id)) {
            // Master firing apprentice
            await UserFirestoreService().terminateApprentice(currentUser.id, targetUser.id);
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'تم إلغاء التتلمذ بنجاح' : 'Apprenticeship canceled'), backgroundColor: Colors.green));
          } else if (currentUser.masterId == targetUser.id) {
            // Apprentice requesting to leave
            await UserFirestoreService().sendLeaveRequest(currentUser.id, targetUser.id);
            scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'تم إرسال طلب الموافقة على ترك التتلمذ' : 'Leave request sent to master'), backgroundColor: Colors.green));
          }
          setState(() {});
        } catch (e) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(isAr ? 'حدث خطأ' : 'Error occurred'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget _buildProductsTab(BuildContext context, UserModel user, String locale) {
    if (user.favoriteProductIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              locale == 'ar' ? 'لا توجد منشورات أو منتجات محفوظة' : 'No saved posts or products',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return FutureBuilder<List<PostModel?>>(
      future: Future.wait(user.favoriteProductIds.map((id) async {
        try {
          final post = await FirestoreService().getPost(id);
          if (post == null) {
            // Auto-clean silently in background
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AuthProvider>().toggleFavoriteProduct(id);
            });
          }
          return post;
        } catch (e) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthProvider>().toggleFavoriteProduct(id);
          });
          return null;
        }
      })),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(locale == 'ar' ? 'حدث خطأ' : 'An error occurred'));
        }

        final products = snapshot.data?.whereType<PostModel>().toList() ?? [];
        if (products.isEmpty) {
          return Center(
            child: Text(
              locale == 'ar' ? 'لا توجد منشورات أو منتجات محفوظة' : 'No saved posts or products',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final imageUrl = product.allImageUrls.isNotEmpty ? product.allImageUrls.first : null;
            
            return GestureDetector(
              onTap: () {
                if (product.price != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailsScreen(post: product)),
                  );
                }
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
                          if (imageUrl != null)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.grey[200]),
                              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                            )
                          else
                            Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                          
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
                                onPressed: () {
                                  context.read<AuthProvider>().toggleFavoriteProduct(product.id);
                                },
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
                            Text(
                              product.caption ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (product.price != null && product.price! > 0)
                              Text(
                                '${product.price} ${locale == 'ar' ? 'ج.س' : 'SDG'}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
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
}
