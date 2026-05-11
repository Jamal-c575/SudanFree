import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';

import '../freelancers/browse_freelancers_screen.dart';
import '../../providers/posts_provider.dart';
import '../../providers/job_provider.dart';
import '../requests/requests_screen.dart';
import '../shops/browse_shops_screen.dart';
import '../posts/posts_feed_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0; // Dashboard is home now
  final List<int> _history = [0];
  Key _freelancersKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    if (user == null) return;

    final userProvider = context.read<UserProvider>();
    userProvider.setUserState(user.state); // Region-priority: 75% local
    userProvider.fetchFreelancers();
    userProvider.fetchShops();
    context.read<PostsProvider>().fetchPosts();
    context.read<JobProvider>().fetchJobs();
    context.read<ChatProvider>().fetchChats(user.id);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }


  Future<void> _checkForUpdates() async {
    try {
      final info = await FirestoreService().getAppVersionInfo();
      if (info.isEmpty) return;

      final latestVersion = info['version'] as String?;
      if (latestVersion == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (latestVersion != currentVersion) {
        if (!mounted) return;
        _showUpdateDialog(
          context,
          latestVersion,
          info['force_update'] as bool? ?? false,
          info['url'] as String? ?? 'https://jamall123.github.io/HOME_WEB/sudan-free.html',
          info['message_ar'] as String?,
          info['message_en'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog(BuildContext context, String version, bool force, String url, String? messageAr, String? messageEn) {
    final isArabic = context.read<LocaleProvider>().isArabic;
    
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => PopScope(
        canPop: !force,
        child: AlertDialog(
          title: Text(isArabic ? 'تحديث جديد متوفر!' : 'New Update Available!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                context.read<LocaleProvider>().isArabic
                    ? (messageAr ?? 'يتوفر إصدار جديد ($version). يرجى التحديث للحصول على أفضل تجربة.')
                    : (messageEn ?? 'A new version ($version) is available. Please update for the best experience.'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ElevatedButton(
              onPressed: () {
                _launchURL(url);
                if (!force) Navigator.pop(ctx);
              },
              child: Text(context.read<LocaleProvider>().isArabic ? 'تحديث الآن' : 'Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       debugPrint('Could not launch $url');
    }
  }

  /// Navigate to a specific tab — used by DashboardScreen
  void _navigateToTab(int index) {
    if (index >= 0 && index <= 4) {
      setState(() {
        _currentIndex = index;
        _history.remove(index);
        _history.add(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;

    final screens = [
      DashboardScreen(onNavigateToTab: _navigateToTab),    // 0 - الرئيسية
      BrowseFreelancersScreen(key: _freelancersKey),        // 1 - الخدمات
      const BrowseShopsScreen(),                            // 2 - المتاجر
      const PostsFeedScreen(),                              // 3 - المجتمع
      const RequestsScreen(),                               // 4 - الطلبات
    ];

    return PopScope(
      canPop: _currentIndex == 0 && _history.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            _currentIndex = _history.last;
          });
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _history.clear();
            _history.add(0);
          });
        }
      },
      child: Scaffold(
        extendBody: true, // المحتوى يمتد تحت الشريط العائم
        body: Stack(
          children: [
            // Use Offstage instead of IndexedStack to reduce memory usage
            // Offstage still keeps widgets in tree but doesn't render them
            for (int i = 0; i < screens.length; i++)
              Offstage(
                offstage: _currentIndex != i,
                child: screens[i],
              ),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1A2332).withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: locale == 'ar' ? 'الرئيسية' : 'Home',
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.work_outline,
                        activeIcon: Icons.work,
                        label: l10n.freelancers,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.store_outlined,
                        activeIcon: Icons.store,
                        label: l10n.shops,
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum,
                        label: l10n.community,
                        isDark: isDark,
                        hasBadge: context.watch<PostsProvider>().hasNewPosts,
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: Icons.assignment_outlined,
                        activeIcon: Icons.assignment,
                        label: locale == 'ar' ? 'الطلبات' : 'Requests',
                        isDark: isDark,
                        hasBadge: false, // Could be hooked to a provider if needed
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    bool hasBadge = false,
    int badgeCount = 0,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive 
        ? AppColors.primary 
        : isDark 
            ? const Color(0xFF94A3B8) 
            : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) {
          setState(() {
            if (index == 1) _freelancersKey = UniqueKey();
            if (index == 3) context.read<PostsProvider>().fetchPosts(forceRefresh: true);
          });
        } else {
          setState(() {
            _currentIndex = index;
            _history.remove(index);
            _history.add(index);
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة مع Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: isActive ? 12 : 6,
                vertical: isActive ? 5 : 3,
              ),
              decoration: BoxDecoration(
                color: isActive 
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Badge(
                isLabelVisible: hasBadge || badgeCount > 0,
                label: badgeCount > 0 
                    ? Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      )
                    : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isActive ? activeIcon : icon,
                    key: ValueKey(isActive),
                    size: isActive ? 22 : 20,
                    color: color,
                  ),
                ),
              ),
            ),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isActive ? 10 : 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                fontFamily: 'Cairo',
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
