import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/search_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/cards/freelancer_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../profile/profile_screen.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class SmartSearchDelegate extends SearchDelegate<UserModel?> {
  @override
  String get searchFieldLabel => 'ابحث عن مهارات، حرفيين، مواقع...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final searchProvider = context.read<SearchProvider>();
    final locale = context.read<LocaleProvider>().locale.languageCode;
    final currentUser = context.read<AuthProvider>().user;

    return FutureBuilder(
      future: searchProvider.searchFreelancers(query: query),
      builder: (context, snapshot) {
        return Consumer<SearchProvider>(
          builder: (context, search, _) {
            if (search.isLoading) return const LoadingIndicator();
            if (search.errorMessage != null) return Center(child: Text(search.errorMessage!));
            
            final results = search.searchResults;
            if (results.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      locale == 'ar' ? 'لا توجد نتائج لـ "$query"' : 'No results for "$query"',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locale == 'ar' ? 'جرّب كلمات أخرى أو تحقق من الإملاء' : 'Try different keywords or check spelling',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    locale == 'ar' ? '${results.length} نتيجة' : '${results.length} results',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final freelancer = results[index];
                      return FreelancerCard(
                        freelancer: freelancer,
                        locale: locale,
                        currentUserId: currentUser?.id,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen(userId: freelancer.id)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final locale = context.read<LocaleProvider>().locale.languageCode;
    final isAr = locale == 'ar';
    
    if (query.isEmpty) {
      return _buildEmptyState(context, isAr);
    }

    // Trigger suggestions update
    final searchProvider = context.read<SearchProvider>();
    searchProvider.updateSuggestions(query);

    return Consumer<SearchProvider>(
      builder: (context, search, _) {
        final suggestions = search.suggestions;

        if (suggestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'اضغط بحث للعرض الكامل' : 'Press search for full results',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getSuggestionIcon(suggestion),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                suggestion,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
              onTap: () {
                query = suggestion;
                showResults(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    // Popular search categories
    final quickSearches = [
      {'label': isAr ? 'سباك' : 'Plumber', 'icon': Icons.plumbing},
      {'label': isAr ? 'كهربائي' : 'Electrician', 'icon': Icons.electrical_services},
      {'label': isAr ? 'نجار' : 'Carpenter', 'icon': Icons.carpenter},
      {'label': isAr ? 'دهان' : 'Painter', 'icon': Icons.format_paint},
      {'label': isAr ? 'ميكانيكي' : 'Mechanic', 'icon': Icons.build},
      {'label': isAr ? 'مصمم' : 'Designer', 'icon': Icons.design_services},
      {'label': isAr ? 'مبرمج' : 'Developer', 'icon': Icons.code},
      {'label': isAr ? 'مطعم' : 'Restaurant', 'icon': Icons.restaurant},
      {'label': isAr ? 'صيدلية' : 'Pharmacy', 'icon': Icons.local_pharmacy},
      {'label': isAr ? 'ملابس' : 'Clothing', 'icon': Icons.checkroom},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Icon(Icons.search, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  isAr ? 'ابحث عن أفضل الحرفيين والخدمات' : 'Find the best professionals & services',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Quick Searches
          Text(
            isAr ? '🔥 بحث سريع' : '🔥 Quick Search',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickSearches.map((item) {
              return ActionChip(
                avatar: Icon(item['icon'] as IconData, size: 18, color: AppColors.primary),
                label: Text(
                  item['label'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  query = item['label'] as String;
                  showResults(context);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'نصائح البحث' : 'Search Tips',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? '• ابحث بالاسم أو المهنة أو الموقع\n• جرّب "سباك في أم درمان" للبحث المركب\n• يمكنك كتابة اسم الحي أو الولاية'
                      : '• Search by name, profession, or location\n• Try "plumber in Omdurman" for combined search\n• You can type a neighborhood or state name',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSuggestionIcon(String suggestion) {
    // Try to match with known categories
    final lower = suggestion.toLowerCase();
    if (lower.contains('سباك') || lower.contains('plumb')) return Icons.plumbing;
    if (lower.contains('كهرب') || lower.contains('electr')) return Icons.electrical_services;
    if (lower.contains('نجار') || lower.contains('carpen')) return Icons.carpenter;
    if (lower.contains('دهان') || lower.contains('paint')) return Icons.format_paint;
    if (lower.contains('ميكانيك') || lower.contains('mechan')) return Icons.build;
    if (lower.contains('مصمم') || lower.contains('design')) return Icons.design_services;
    if (lower.contains('مبرمج') || lower.contains('develop')) return Icons.code;
    if (lower.contains('مطعم') || lower.contains('restau')) return Icons.restaurant;
    if (lower.contains('متجر') || lower.contains('shop') || lower.contains('معرض')) return Icons.store;
    return Icons.search;
  }
}
