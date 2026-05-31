import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import 'product_detail_screen.dart';

class ShopDashboardScreen extends StatelessWidget {
  final UserModel shop;

  const ShopDashboardScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(l10n.localeName == 'ar' ? 'لوحة المعلومات' : 'Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShopInfoCard(context, isDark),
            const SizedBox(height: 24),
            _buildStatsGrid(l10n, isDark),
            const SizedBox(height: 24),
            Text(
              l10n.localeName == 'ar' ? 'إحصائيات المنتجات' : 'Products Insights',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildProductsList(l10n, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildShopInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: shop.profileImageUrl != null ? CachedNetworkImageProvider(shop.profileImageUrl!) : null,
            child: shop.profileImageUrl == null ? const Icon(Icons.store, size: 30, color: AppColors.primary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  shop.getShopCategoryName(AppLocalizations.of(context)!.localeName),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          icon: Icons.people_alt,
          color: Colors.blue,
          value: shop.followers.length.toString(),
          title: l10n.localeName == 'ar' ? 'المتابعين' : 'Followers',
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.auto_graph_rounded,
          color: Colors.teal,
          value: shop.dailyProfileViews.toString(),
          title: l10n.localeName == 'ar' ? 'الزيارات اليومية' : 'Daily Visits',
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.remove_red_eye,
          color: Colors.purple,
          value: shop.profileViews.toString(),
          title: l10n.localeName == 'ar' ? 'إجمالي الزيارات' : 'Total Visits',
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          color: Colors.amber,
          value: shop.rating > 0 ? shop.rating.toStringAsFixed(1) : '--',
          title: l10n.localeName == 'ar' ? 'التقييم' : 'Rating',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required Color color, required String value, required String title, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildProductsList(AppLocalizations l10n, bool isDark) {
    return StreamBuilder<List<PostModel>>(
      stream: FirestoreService().getUserPosts(shop.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
        }

        final products = (snapshot.data ?? []).where((p) => p.showInProfile).toList();

        // Sort by viewsCount descending, then by date
        products.sort((a, b) {
          if (a.viewsCount != b.viewsCount) return b.viewsCount.compareTo(a.viewsCount);
          return b.createdAt.compareTo(a.createdAt);
        });

        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                l10n.localeName == 'ar' ? 'لا توجد منتجات لعرض إحصائياتها' : 'No products to show insights for.',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCompactTile(context, product, isDark);
          },
        );
      },
    );
  }

  Widget _buildProductCompactTile(BuildContext context, PostModel product, bool isDark) {
    final imageUrl = product.allImageUrls.isNotEmpty ? product.allImageUrls.first : null;
    final caption = product.caption ?? 'منتج بدون وصف';
    final title = caption.split('\n').first;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16), right: Radius.circular(0)), // Adjust for RTL if needed, but horizontal works fine usually. Actually, let's use all corners slightly.
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[200], width: 90, height: 90),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[200], width: 90, height: 90, child: const Icon(Icons.broken_image)),
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                    ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  if (product.price != null)
                    Text(
                      '${product.price} SDG',
                      style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                ],
              ),
            ),
            // Views Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_rounded, color: Colors.purple, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    '${product.viewsCount}',
                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 14),
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
