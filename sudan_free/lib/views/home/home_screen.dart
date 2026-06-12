import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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
import '../squads/squads_explorer_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firestore_service.dart';
import 'dashboard_screen.dart';

class BottomBarVisibilityProvider extends ChangeNotifier {
  bool _isVisible = true;
  bool get isVisible => _isVisible;

  void setVisible(bool value) {
    if (_isVisible != value) {
      _isVisible = value;
      notifyListeners();
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0; // Dashboard is home now
  final List<int> _history = [0];
  final BottomBarVisibilityProvider _visibilityProvider = BottomBarVisibilityProvider();
  
  // Track which tabs have been visited to lazy-load them and save memory
  final List<bool> _initializedTabs = [true, false, false, false];
  
  // Keys for refreshing tabs
  Key _dashboardKey = UniqueKey();
  Key _squadsKey = UniqueKey();
  Key _requestsKey = UniqueKey();

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
          info['url'] as String? ?? 'https://sudanfree.com/sudan-free.html',
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
    if (index >= 0 && index <= 3) {
      setState(() {
        _currentIndex = index;
        _history.remove(index);
        _history.add(index);
        _initializedTabs[index] = true; // Mark as initialized
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
      DashboardScreen(key: _dashboardKey, onNavigateToTab: _navigateToTab),    // 0 - الرئيسية
      const PostsFeedScreen(),                              // 1 - المجتمع (يحدث عبر الـ Provider)
      SquadsExplorerScreen(key: _squadsKey),                // 2 - المجموعات
      RequestsScreen(key: _requestsKey),                               // 3 - الطلبات
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
      child: ChangeNotifierProvider.value(
        value: _visibilityProvider,
        child: Scaffold(
          extendBody: true, // المحتوى يمتد تحت الشريط العائم
          body: NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                if (notification.direction == ScrollDirection.reverse) {
                  _visibilityProvider.setVisible(false);
                } else if (notification.direction == ScrollDirection.forward) {
                  _visibilityProvider.setVisible(true);
                }
              }
              return false;
            },
            child: Stack(
              children: [
                // Lazy-load screens: Only keep them in the tree if they have been visited
                for (int i = 0; i < screens.length; i++)
                  if (_initializedTabs[i])
                    Offstage(
                      offstage: _currentIndex != i,
                      child: screens[i],
                    ),
              ],
            ),
          ),
          bottomNavigationBar: Consumer<BottomBarVisibilityProvider>(
            builder: (context, visibility, child) {
              return AnimatedSlide(
                offset: visibility.isVisible ? Offset.zero : const Offset(0, 1.2),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: child,
              );
            },
            child: Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final bottomPadding = MediaQuery.of(context).padding.bottom;
                
                // التكيف مع شريط التنقل الخاص بالنظام (الأزرار الثلاثة أو الإيماءات)
                // إذا كان هناك شريط أزرار (padding كبير) نرفعه قليلاً، وإذا كان إيماءات نجعله أقرب للحافة
                final bottomMargin = bottomPadding > 30 ? bottomPadding + 8 : bottomPadding + 14;
            
            return Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
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
                        icon: Icons.forum_outlined,
                        activeIcon: Icons.forum,
                        label: l10n.community,
                        isDark: isDark,
                        hasBadge: context.watch<PostsProvider>().hasNewPosts,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.groups_outlined,
                        activeIcon: Icons.groups,
                        label: locale == 'ar' ? 'المجموعات' : 'Squads',
                        isDark: isDark,
                      ),
                      _buildNavItem(
                        index: 3,
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
    bool isProminent = false,
  }) {
    return _NavItemWidget(
      index: index,
      icon: icon,
      activeIcon: activeIcon,
      label: label,
      isDark: isDark,
      isActive: _currentIndex == index,
      hasBadge: hasBadge,
      badgeCount: badgeCount,
      isProminent: isProminent,
      onTap: () {
        if (_currentIndex != index) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
            _history.remove(index);
            _history.add(index);
            _initializedTabs[index] = true; // Mark as initialized
          });
        }
      },
      onRefresh: () {
        setState(() {
          if (index == 0) _dashboardKey = UniqueKey();
          if (index == 1) context.read<PostsProvider>().fetchPosts(forceRefresh: true);
          if (index == 2) _squadsKey = UniqueKey();
          if (index == 3) _requestsKey = UniqueKey();
        });
      },
    );
  }
}

class _NavItemWidget extends StatefulWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isDark;
  final bool isActive;
  final bool hasBadge;
  final int badgeCount;
  final bool isProminent;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const _NavItemWidget({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isDark,
    required this.isActive,
    required this.hasBadge,
    required this.badgeCount,
    this.isProminent = false,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    widget.onRefresh();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive 
        ? AppColors.primary 
        : widget.isDark 
            ? const Color(0xFF94A3B8) 
            : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.isActive ? _triggerRefresh : null,
      onLongPress: widget.isActive ? _triggerRefresh : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isActive ? 12 : 6,
                  vertical: widget.isActive ? 5 : 3,
                ),
                decoration: BoxDecoration(
                  color: widget.isActive 
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (widget.isProminent ? AppColors.secondary.withValues(alpha: 0.15) : Colors.transparent),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Badge(
                  isLabelVisible: widget.hasBadge || widget.badgeCount > 0,
                  label: widget.badgeCount > 0 
                      ? Text(
                          widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        )
                      : null,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      widget.isActive ? widget.activeIcon : widget.icon,
                      key: ValueKey(widget.isActive),
                      size: widget.isActive ? (widget.isProminent ? 26 : 22) : (widget.isProminent ? 24 : 20),
                      color: widget.isProminent && !widget.isActive ? AppColors.secondary : color,
                    ),
                  ),
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: widget.isActive ? 10 : 9,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isProminent && !widget.isActive ? AppColors.secondary : color,
                  fontFamily: 'Cairo',
                ),
                child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
