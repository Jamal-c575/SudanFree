import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/job_titles_utils.dart';
import '../../services/cloudinary_service.dart';
import '../profile/profile_screen.dart';

enum FilterType { nearYou, topRated, newest, shops, categories }

class FilteredProvidersScreen extends StatefulWidget {
  final FilterType filterType;
  final String title;

  const FilteredProvidersScreen({super.key, required this.filterType, required this.title});

  @override
  State<FilteredProvidersScreen> createState() => _FilteredProvidersScreenState();
}

class _FilteredProvidersScreenState extends State<FilteredProvidersScreen> {
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final currentUser = context.watch<AuthProvider>().user;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<UserModel> displayList = [];

    if (userProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    switch (widget.filterType) {
      case FilterType.nearYou:
        displayList = List<UserModel>.from(userProvider.freelancers).where((f) {
          if (currentUser?.state == null) return true;
          return f.state == currentUser!.state;
        }).toList();
        break;
      case FilterType.topRated:
        // Combine freelancers + shops, then sort by totalStars (rating × reviewsCount)
        // This is fairer: someone with 50 reviews at 4.8 ranks higher than 1 review at 5.0
        displayList = [
          ...userProvider.freelancers,
          ...userProvider.shops,
        ];
        displayList.sort((a, b) {
          // Primary: totalStars (weighted score)
          final cmp = b.totalStars.compareTo(a.totalStars);
          if (cmp != 0) return cmp;
          // Secondary: average rating as tiebreaker
          return b.rating.compareTo(a.rating);
        });
        break;
      case FilterType.newest:
        displayList = List<UserModel>.from(userProvider.freelancers)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FilterType.shops:
        displayList = userProvider.shops;
        break;
      case FilterType.categories:
        // Default list for categories option (could later open a dropdown)
        displayList = userProvider.freelancers;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: displayList.isEmpty
          ? Center(
              child: Text(
                locale == 'ar' ? 'لا توجد نتائج' : 'No results found',
                style: TextStyle(color: AppColors.softGrey, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final user = displayList[index];
                final isShop = user.role == UserRole.shop;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
                  ),
                  child: Container(
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
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: isShop ? AppColors.sudanGradient : AppColors.primaryGradient,
                            ),
                            child: user.profileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: CloudinaryService.getOptimizedUrl(
                                      user.profileImageUrl!, width: 300, quality: 'auto'),
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300,
                                    placeholder: (_, __) => Center(
                                      child: Icon(isShop ? Icons.store : Icons.person, size: 36, color: Colors.white54),
                                    ),
                                    errorWidget: (_, __, ___) => Center(
                                      child: Icon(isShop ? Icons.store : Icons.person, size: 36, color: Colors.white54),
                                    ),
                                  )
                                : Center(
                                    child: Icon(isShop ? Icons.store : Icons.person, size: 36, color: Colors.white54),
                                  ),
                          ),
                        ),
                        // Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (isShop && user.shopCategory != null)
                                  Text(
                                    user.getShopCategoryName(locale),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.desertOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else if (!isShop)
                                  Text(
                                    user.jobTitle?.isNotEmpty == true 
                                        ? JobTitlesUtils.getLocalizedTitle(user.jobTitle!, locale) 
                                        : (user.skills.isNotEmpty 
                                            ? user.skills.map((s) => JobTitlesUtils.getLocalizedTitle(s, locale)).join('، ') 
                                            : user.getRoleDisplayName(locale)),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: AppColors.softGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        user.state ?? (locale == 'ar' ? 'غير محدد' : 'Unknown'),
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
                                const SizedBox(height: 4),
                                if (user.bio?.isNotEmpty == true)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        user.bio!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.softGrey.withValues(alpha: 0.8),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                else
                                  const Spacer(),
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, size: 16, color: AppColors.sudanGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.rating > 0
                                          ? user.rating.toStringAsFixed(1)
                                          : (locale == 'ar' ? 'جديد' : 'New'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodySmall?.color,
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
                );
              },
            ),
    );
  }
}
