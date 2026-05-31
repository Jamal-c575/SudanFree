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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: locale == 'ar' ? (!isFreelancer ? 'الحسابات المحفوظة' : 'الزملاء') : (!isFreelancer ? 'Saved Accounts' : 'Partners')),
              Tab(text: locale == 'ar' ? 'المنشورات والمنتجات المحفوظة' : 'Saved Posts & Products'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(context, user, isFreelancer, locale),
            _buildProductsTab(context, user, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, UserModel user, bool isFreelancer, String locale) {
    final userIds = <String>{...user.favoriteUserIds, ...user.partnerIds}.toList();
    
    if (userIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(!isFreelancer ? Icons.favorite_border : Icons.group_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              locale == 'ar' 
                  ? (!isFreelancer ? 'لا توجد حسابات مفضلة بعد' : 'لا يوجد زملاء حالياً') 
                  : (!isFreelancer ? 'No favorite accounts yet' : 'No partners yet'),
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
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final targetUser = users[index];
            final isFavorite = user.favoriteUserIds.contains(targetUser.id);
            final isPartner = user.partnerIds.contains(targetUser.id);
            
            return ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: targetUser.id))),
              leading: CircleAvatar(
                backgroundImage: targetUser.profileImageUrl != null ? NetworkImage(targetUser.profileImageUrl!) : null,
                child: targetUser.profileImageUrl == null ? Icon(targetUser.role == UserRole.shop ? Icons.store : Icons.person) : null,
              ),
              title: Text(targetUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(targetUser.jobTitle ?? (locale == 'ar' ? 'حساب في سودان فري' : 'SudanFree Account')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPartner)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        locale == 'ar' ? 'زميل' : 'Partner',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (isPartner)
                    IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      tooltip: locale == 'ar' ? 'إلغاء الزمالة' : 'Remove Partner',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(locale == 'ar' ? 'إلغاء الزمالة' : 'Remove Partner'),
                            content: Text(locale == 'ar' ? 'هل أنت متأكد من إلغاء زمالة ${targetUser.name}؟' : 'Are you sure you want to remove ${targetUser.name}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(locale == 'ar' ? 'تراجع' : 'Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(locale == 'ar' ? 'حذف' : 'Remove', style: const TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await context.read<AuthProvider>().handlePartnerRequest(targetUser.id, false);
                          // Re-fetch partners to update UI
                          context.read<AuthProvider>().fetchPartners(forceRefresh: true);
                        }
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey,
                    ),
                    tooltip: locale == 'ar' ? 'المفضلة' : 'Favorite',
                    onPressed: () {
                      context.read<AuthProvider>().toggleFavoriteUser(targetUser.id);
                    },
                  ),
                ],
              ),
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          },
        );
      },
    );
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
