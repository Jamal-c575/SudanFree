import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Added
import 'package:share_plus/share_plus.dart'; // Added
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../safety/safety_tips_screen.dart';
import '../about/about_app_screen.dart';
import '../../widgets/common/glass_container.dart';
import '../settings/privacy_policy_screen.dart';
import '../settings/admin_dashboard_screen.dart';
import '../auth/identity_verification_screen.dart';
import '../jobs/my_agreements_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constants/sudan_locations.dart';
import '../../services/smart_guide_service.dart';
import '../subscription/pro_account_screen.dart';
import '../profile/identity_verification_screen.dart' as id_verify;

class SettingsScreen extends StatefulWidget {
  final bool asBottomSheet;
  const SettingsScreen({super.key, this.asBottomSheet = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SmartGuideService.showMicroTip(
        context,
        messageAr: 'يمكنك تعديل اهتماماتك لتحسين المنشورات التي تراها ⚙️',
        messageEn: 'Update your interests to improve your feed ⚙️',
        tipId: 'settings_tip',
        icon: Icons.settings_rounded,
      );
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    final l10n = AppLocalizations.of(context)!;

    final listContent = ListView(
      padding: widget.asBottomSheet
          ? const EdgeInsets.fromLTRB(16, 0, 16, 24)
          : const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: AppLocalizations.of(context)!.appearance),
        const SizedBox(height: 8),

        // Dark Mode Toggle
        _SettingsTile(
          icon: isDark ? Icons.dark_mode : Icons.light_mode,
          title: AppLocalizations.of(context)!.darkMode,
          trailing: Switch(
            value: isDark,
            onChanged: (value) => themeProvider.toggleTheme(),
            activeThumbColor: AppColors.primary,
          ),
        ),

        const SizedBox(height: 8),

        // Availability Toggle (Freelancers Only)
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final role = auth.user?.role;
            if (role != UserRole.freelancer &&
                role != UserRole.techService &&
                role != UserRole.privateService &&
                role != UserRole.shop) {
              return const SizedBox.shrink();
            }
            final isAvailable = auth.user?.isAvailable ?? true;
            return Column(
              children: [
                _SectionHeader(title: AppLocalizations.of(context)!.account),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.access_time,
                  iconColor: isAvailable ? AppColors.success : AppColors.error,
                  title: isAvailable
                      ? AppLocalizations.of(context)!.availableForWork
                      : AppLocalizations.of(context)!.currentlyUnavailable,
                  trailing: Switch(
                    value: isAvailable,
                    onChanged: (value) => auth.toggleAvailability(),
                    activeThumbColor: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),

                // Map Visibility Toggle
                _SettingsTile(
                  icon: Icons.map,
                  iconColor: (auth.user?.showOnMap ?? true)
                      ? AppColors.primary
                      : Colors.grey,
                  title: AppLocalizations.of(context)!.showOnMap,
                  subtitle: (auth.user?.showOnMap ?? true)
                      ? AppLocalizations.of(context)!.visibleToAll
                      : AppLocalizations.of(context)!.hiddenFromMap,
                  trailing: Switch(
                    value: auth.user?.showOnMap ?? true,
                    onChanged: (value) => auth.toggleShowOnMap(),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Update Location Button
                _UpdateLocationTile(auth: auth, locale: locale),
                const SizedBox(height: 8),
              ],
            );
          },
        ),

        // Glassmorphism Toggle
        _SettingsTile(
          icon: Icons.blur_on,
          iconColor: themeProvider.isGlassmorphismEnabled
              ? AppColors.primary
              : Colors.grey,
          title: AppLocalizations.of(context)!.glassmorphismPerformance,
          subtitle: themeProvider.isGlassmorphismEnabled
              ? (AppLocalizations.of(context)!.enabledAppWillCloseToApply)
              : (AppLocalizations.of(context)!.disabledAppWillCloseToApply),
          trailing: Switch(
            value: themeProvider.isGlassmorphismEnabled,
            onChanged: (value) {
              themeProvider.toggleGlassmorphism();
              Future.delayed(const Duration(milliseconds: 400), () {
                SystemNavigator.pop();
              });
            },
            activeThumbColor: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),

        // Language Toggle
        _SettingsTile(
          icon: Icons.language,
          title: l10n.language,
          subtitle: AppLocalizations.of(context)!.english,
          onTap: () => context.read<LocaleProvider>().toggleLocale(),
          trailing:
              const Icon(Icons.sync_alt, size: 20, color: AppColors.primary),
        ),

        const SizedBox(height: 8),

        // Identity Verification - NEW
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final isVerified = auth.user?.isVerified ?? false;
            return _SettingsTile(
              icon: Icons.handshake,
              iconColor: isVerified ? AppColors.primary : Colors.orange,
              title: AppLocalizations.of(context)!.accountVerification,
              subtitle: isVerified
                  ? (AppLocalizations.of(context)!.verifiedHandshakeIconShowsBesideYour)
                  : (AppLocalizations.of(context)!.comingSoonHandshakeIconBesideYour),
              trailing: isVerified
                  ? const Icon(Icons.handshake,
                      color: AppColors.primary, size: 22)
                  : null,
              openScreen: const IdentityVerificationScreen(),
            );
          },
        ),

        // Admin Dashboard - NEW
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.user?.role != UserRole.admin) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.admin_panel_settings,
                  iconColor: Colors.deepPurple,
                  title:
                      AppLocalizations.of(context)!.adminDashboard,
                  subtitle: AppLocalizations.of(context)!.manageVerificationsStats,
                  openScreen: const AdminDashboardScreen(),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 8),

        // My Agreements
        _SettingsTile(
          icon: Icons.assignment,
          iconColor: Colors.blue,
          title: AppLocalizations.of(context)!.myAgreements,
          subtitle: AppLocalizations.of(context)!.manageContractsAndTrackProgress,
          openScreen: const MyAgreementsScreen(),
        ),

        const SizedBox(height: 20),
        _SectionHeader(
            title: AppLocalizations.of(context)!.safetySecurity),
        const SizedBox(height: 8),

        // Safety Tips - NEW
        _SettingsTile(
          icon: Icons.security,
          iconColor: Colors.green,
          title: AppLocalizations.of(context)!.safetyTips,
          subtitle: AppLocalizations.of(context)!.protectYourselfFromFraud,
          openScreen: const SafetyTipsScreen(),
        ),

        const SizedBox(height: 8),

        // Notifications Toggle
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final isPushEnabled =
                auth.user?.notificationSettings['pushEnabled'] ?? true;
            return _SettingsTile(
              icon: isPushEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              iconColor: isPushEnabled ? AppColors.primary : Colors.grey,
              title: AppLocalizations.of(context)!.notifications,
              subtitle: isPushEnabled
                  ? AppLocalizations.of(context)!.enabled
                  : AppLocalizations.of(context)!.disabled,
              trailing: Switch(
                value: isPushEnabled,
                onChanged: (value) => auth.togglePushNotifications(value),
                activeThumbColor: AppColors.primary,
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Client Interests Selection
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.user;
            if (user == null) return const SizedBox.shrink();
            final totalInterests =
                (user.shopInterests.length + user.serviceInterests.length);
            return Column(
              children: [
                _SettingsTile(
                  icon: Icons.interests_rounded,
                  iconColor: AppColors.desertOrange,
                  title: AppLocalizations.of(context)!.myInterests,
                  subtitle: totalInterests > 0
                      ? AppLocalizations.of(context)!.interestsSelected(totalInterests)
                      : AppLocalizations.of(context)!.setInterestsToPersonalizeContent,
                  onTap: () => _showInterestsSheet(context, locale),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),

        // Privacy
        _SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.privacyPolicy,
          openScreen: const PrivacyPolicyScreen(),
        ),

        const SizedBox(height: 20),
        _SectionHeader(
            title: AppLocalizations.of(context)!.connectWithUs),
        const SizedBox(height: 8),

        // Connect with Us section loaded from Firestore
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('settings')
              .doc('app_settings')
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            final whatsapp = data['whatsapp'] ?? 'https://wa.me/249900578357';
            final facebook = data['facebook'] ??
                'https://www.facebook.com/share/18J8UXiEDe/';
            final telegram = data['telegram'] ?? 'https://t.me/JamalJhome';
            final website =
                data['website'] ?? 'https://sudanfree.com/sudan-free.html';
            final shareTextAr = data['share_text_ar'] ??
                'جرب تطبيق سودان فري للعثور على فرص عمل ومستقلين موثوقين! حمل التطبيق الآن: https://sudanfree.com/sudan-free.html';
            final shareTextEn = data['share_text_en'] ??
                'Try SudanFree to find jobs and trusted freelancers! Download now: https://sudanfree.com/sudan-free.html';

            return Column(
              children: [
                _SettingsTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.green,
                  title: AppLocalizations.of(context)!.whatsapp,
                  subtitle: AppLocalizations.of(context)!.contactSupport,
                  onTap: () => _launchURL(whatsapp),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.facebook,
                  iconColor: Colors.blue[800],
                  title: AppLocalizations.of(context)!.facebook,
                  onTap: () => _launchURL(facebook),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.send,
                  iconColor: Colors.blue[400],
                  title: AppLocalizations.of(context)!.telegram,
                  onTap: () => _launchURL(telegram),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.language,
                  iconColor: Colors.purple,
                  title: AppLocalizations.of(context)!.website,
                  onTap: () => _launchURL(website),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.share,
                  iconColor: Colors.orange,
                  title: AppLocalizations.of(context)!.shareApp,
                  onTap: () async {
                    final text = locale == 'ar' ? shareTextAr : shareTextEn;
                    // ignore: deprecated_member_use
                    await Share.share(text);
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Pro Account
        _SettingsTile(
          icon: Icons.workspace_premium,
          iconColor: const Color(0xFFFFB300),
          title: locale == 'ar' ? 'ترقية الحساب (Pro)' : 'Upgrade Account (Pro)',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProAccountScreen()),
          ),
        ),

        const SizedBox(height: 8),

        // Identity Verification
        _SettingsTile(
          icon: Icons.verified_user,
          iconColor: Colors.green,
          title: locale == 'ar' ? 'تحقق الهوية' : 'Identity Verification',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const id_verify.IdentityVerificationScreen()),
          ),
        ),

        const SizedBox(height: 20),

        // About
        _SettingsTile(
          icon: Icons.info_outline,
          iconColor: AppColors.primary,
          title: AppLocalizations.of(context)!.aboutApp,
          openScreen: const AboutAppScreen(),
        ),

        const SizedBox(height: 12),

        // Logout Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context, locale),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: Text(
              l10n.logout,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );

    Widget finalContent = listContent;

    if (widget.asBottomSheet) {
      finalContent = Column(
        children: [
          // Fixed Header
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  l10n.settings,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Scrollable List
          Expanded(child: listContent),
        ],
      );

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(child: finalContent),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.9),
                AppColors.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    AppColors.primary.withValues(alpha: 0.15)
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    AppColors.primary.withValues(alpha: 0.1)
                  ],
          ),
        ),
        child: SafeArea(child: finalContent),
      ),
    );
  }

  void _showInterestsSheet(BuildContext context, String locale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InterestsBottomSheet(locale: locale),
    );
  }

  void _showLogoutDialog(BuildContext context, String locale) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          blur: 15,
          opacity: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.whatDoYouWantToDo,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.youCanLogoutAndReturnLater,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performLogout(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    AppLocalizations.of(context)!.logout,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeleteAccountConfirmation(context, locale);
                  },
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  label: Text(
                    AppLocalizations.of(context)!.deleteAccountPermanently,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performLogout(BuildContext context) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await context.read<AuthProvider>().signOut(context);

    if (context.mounted) {
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showDeleteAccountConfirmation(BuildContext context, String locale) {
    final TextEditingController reasonController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            borderRadius: BorderRadius.circular(20),
            blur: 15,
            opacity: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.deleteAccountRequest,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.forSecurityReasonsAndToProtect,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.reasonOptionalButSpeedsUpThe,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.black26 : Colors.white54,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() => isLoading = true);
                            final auth = context.read<AuthProvider>();
                            final success = await auth.requestAccountDeletion(reasonController.text.trim());

                            if (success && context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(AppLocalizations.of(context)!.deletionRequestSentSuccessfully),
                                backgroundColor: Colors.green,
                              ));
                              _performLogout(context);
                            } else {
                              setState(() => isLoading = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(AppLocalizations.of(context)!.errorOccurredTryAgain),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(AppLocalizations.of(context)!.confirmRequest, style: const TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? openScreen;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.openScreen,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.openScreen != null) {
      setState(() => _scale = 0.97);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.openScreen != null) {
      setState(() => _scale = 1.0);
    }
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: widget.onTap != null || widget.openScreen != null ? _onTapDown : null,
      onTapUp: widget.onTap != null || widget.openScreen != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null || widget.openScreen != null ? _onTapCancel : null,
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else if (widget.openScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => widget.openScreen!),
          );
        }
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.4),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade200.withValues(alpha: 0.5),
            width: 0.5,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: color, size: 22),
            ),
            title: Text(widget.title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: widget.subtitle != null
                ? Text(widget.subtitle!,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600]))
                : null,
            trailing: widget.trailing ??
                ((widget.onTap != null || widget.openScreen != null)
                    ? Icon(Icons.chevron_right,
                        size: 20, color: Colors.grey[400])
                    : null),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Interests Bottom Sheet
// ══════════════════════════════════════════════════════════════════
class _InterestsBottomSheet extends StatefulWidget {
  final String locale;
  const _InterestsBottomSheet({required this.locale});

  @override
  State<_InterestsBottomSheet> createState() => _InterestsBottomSheetState();
}

class _InterestsBottomSheetState extends State<_InterestsBottomSheet> {
  late Set<String> _selectedShopInterests;
  late Set<String> _selectedServiceInterests;
  bool _isSaving = false;

  // Shop categories with icons
  static const List<Map<String, dynamic>> _shopCategories = [
    {
      'key': 'electronics',
      'ar': 'إلكترونيات',
      'en': 'Electronics',
      'icon': Icons.devices
    },
    {
      'key': 'clothing',
      'ar': 'ملابس',
      'en': 'Clothing',
      'icon': Icons.checkroom
    },
    {'key': 'furniture', 'ar': 'أثاث', 'en': 'Furniture', 'icon': Icons.chair},
    {
      'key': 'food',
      'ar': 'مواد غذائية',
      'en': 'Food',
      'icon': Icons.restaurant
    },
    {
      'key': 'restaurant',
      'ar': 'مطاعم',
      'en': 'Restaurants',
      'icon': Icons.local_dining
    },
    {
      'key': 'supermarket',
      'ar': 'سوبرماركت',
      'en': 'Supermarket',
      'icon': Icons.local_grocery_store
    },
    {
      'key': 'pharmacy',
      'ar': 'صيدلية',
      'en': 'Pharmacy',
      'icon': Icons.local_pharmacy
    },
    {
      'key': 'beauty',
      'ar': 'تجميل',
      'en': 'Beauty',
      'icon': Icons.face_retouching_natural
    },
    {
      'key': 'automotive',
      'ar': 'قطع غيار',
      'en': 'Automotive',
      'icon': Icons.directions_car
    },
    {
      'key': 'building',
      'ar': 'مواد بناء',
      'en': 'Building',
      'icon': Icons.construction
    },
    {'key': 'jewelry', 'ar': 'مجوهرات', 'en': 'Jewelry', 'icon': Icons.diamond},
    {
      'key': 'mobile',
      'ar': 'جوالات',
      'en': 'Mobile',
      'icon': Icons.phone_android
    },
    {
      'key': 'bookstore',
      'ar': 'مكتبة',
      'en': 'Bookstore',
      'icon': Icons.menu_book
    },
    {
      'key': 'sports',
      'ar': 'رياضة',
      'en': 'Sports',
      'icon': Icons.sports_soccer
    },
    {'key': 'toys', 'ar': 'ألعاب أطفال', 'en': 'Toys', 'icon': Icons.toys},
    {'key': 'home', 'ar': 'أدوات منزلية', 'en': 'Home', 'icon': Icons.home},
  ];

  // Service categories
  static const List<Map<String, dynamic>> _serviceCategories = [
    {
      'key': 'plumbing',
      'ar': 'سباكة',
      'en': 'Plumbing',
      'icon': Icons.plumbing
    },
    {
      'key': 'electrical',
      'ar': 'كهرباء',
      'en': 'Electrical',
      'icon': Icons.electrical_services
    },
    {
      'key': 'painting',
      'ar': 'دهانات',
      'en': 'Painting',
      'icon': Icons.format_paint
    },
    {
      'key': 'carpentry',
      'ar': 'نجارة',
      'en': 'Carpentry',
      'icon': Icons.handyman
    },
    {
      'key': 'cleaning',
      'ar': 'تنظيف',
      'en': 'Cleaning',
      'icon': Icons.cleaning_services
    },
    {
      'key': 'design',
      'ar': 'تصميم',
      'en': 'Design',
      'icon': Icons.design_services
    },
    {
      'key': 'programming',
      'ar': 'برمجة',
      'en': 'Programming',
      'icon': Icons.code
    },
    {
      'key': 'photography',
      'ar': 'تصوير',
      'en': 'Photography',
      'icon': Icons.camera_alt
    },
    {'key': 'teaching', 'ar': 'تدريس', 'en': 'Teaching', 'icon': Icons.school},
    {
      'key': 'transport',
      'ar': 'نقل',
      'en': 'Transport',
      'icon': Icons.local_shipping
    },
    {
      'key': 'ac_repair',
      'ar': 'تكييف',
      'en': 'AC Repair',
      'icon': Icons.ac_unit
    },
    {
      'key': 'mechanic',
      'ar': 'ميكانيكا',
      'en': 'Mechanic',
      'icon': Icons.build
    },
    {
      'key': 'tailoring',
      'ar': 'خياطة',
      'en': 'Tailoring',
      'icon': Icons.content_cut
    },
    {
      'key': 'catering',
      'ar': 'تموين',
      'en': 'Catering',
      'icon': Icons.dinner_dining
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _selectedShopInterests = Set<String>.from(user?.shopInterests ?? []);
    _selectedServiceInterests = Set<String>.from(user?.serviceInterests ?? []);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    await auth.updateUserProfile({
      'shopInterests': _selectedShopInterests.toList(),
      'serviceInterests': _selectedServiceInterests.toList(),
    });
    if (mounted) {
      setState(() => _isSaving = false);
      if (context.mounted) Navigator.pop(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context)!.interestsSaved),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = widget.locale == 'ar';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.desertOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.interests_rounded,
                      color: AppColors.desertOrange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.myInterests,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        AppLocalizations.of(context)!.chooseToPersonalizeYourFeed,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Services Section ──
                _sectionTitle(
                  icon: Icons.build_circle,
                  title: AppLocalizations.of(context)!.services,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _serviceCategories.map((cat) {
                    final isSelected =
                        _selectedServiceInterests.contains(cat['key']);
                    return _buildInterestChip(
                      label: isAr ? cat['ar'] : cat['en'],
                      icon: cat['icon'] as IconData,
                      isSelected: isSelected,
                      color: AppColors.primary,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          isSelected
                              ? _selectedServiceInterests.remove(cat['key'])
                              : _selectedServiceInterests.add(cat['key']);
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Shops Section ──
                _sectionTitle(
                  icon: Icons.storefront,
                  title: AppLocalizations.of(context)!.shopTypes,
                  color: AppColors.desertOrange,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _shopCategories.map((cat) {
                    final isSelected =
                        _selectedShopInterests.contains(cat['key']);
                    return _buildInterestChip(
                      label: isAr ? cat['ar'] : cat['en'],
                      icon: cat['icon'] as IconData,
                      isSelected: isSelected,
                      color: AppColors.desertOrange,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          isSelected
                              ? _selectedShopInterests.remove(cat['key'])
                              : _selectedShopInterests.add(cat['key']);
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.saveInterests,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _sectionTitle(
      {required IconData icon, required String title, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildInterestChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.12)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? color
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpdateLocationTile extends StatefulWidget {
  final AuthProvider auth;
  final String locale;
  const _UpdateLocationTile({required this.auth, required this.locale});

  @override
  State<_UpdateLocationTile> createState() => _UpdateLocationTileState();
}

class _UpdateLocationTileState extends State<_UpdateLocationTile> {
  bool _isLoading = false;

  String? _matchState(String adminArea) {
    if (adminArea.isEmpty) return null;
    final area = adminArea.toLowerCase();

    if (area.contains('khartoum')) return 'الخرطوم';
    if (area.contains('jazira') || area.contains('gezira')) return 'الجزيرة';
    if (area.contains('river nile')) return 'نهر النيل';
    if (area.contains('northern')) return 'الشمالية';
    if (area.contains('kassala')) return 'كسلا';
    if (area.contains('gedaref') ||
        area.contains('qadaref') ||
        area.contains('qadarif')) {
      return 'القضارف';
    }
    if (area.contains('red sea')) return 'البحر الأحمر';
    if (area.contains('sennar')) return 'سنار';
    if (area.contains('blue nile')) return 'النيل الأزرق';
    if (area.contains('white nile')) return 'النيل الأبيض';
    if (area.contains('north') && area.contains('kordofan')) {
      return 'شمال كردفان';
    }
    if (area.contains('south') && area.contains('kordofan')) {
      return 'جنوب كردفان';
    }
    if (area.contains('west') && area.contains('kordofan')) return 'غرب كردفان';
    if (area.contains('north') && area.contains('darfur')) return 'شمال دارفور';
    if (area.contains('south') && area.contains('darfur')) return 'جنوب دارفور';
    if (area.contains('west') && area.contains('darfur')) return 'غرب دارفور';
    if (area.contains('central') && area.contains('darfur')) {
      return 'وسط دارفور';
    }
    if (area.contains('east') && area.contains('darfur')) return 'شرق دارفور';

    for (var s in SudanLocations.states) {
      if (adminArea.contains(s) || s.contains(adminArea)) return s;
    }
    return null;
  }

  String? _matchLocality(String localityArea, String state) {
    if (localityArea.isEmpty) return null;
    final area = localityArea.toLowerCase();
    final localities = SudanLocations.getLocalities(state);

    if (area.contains('khartoum north') || area.contains('bahri')) {
      return 'بحري';
    }
    if (area.contains('khartoum')) return 'الخرطوم';
    if (area.contains('omdurman')) return 'أم درمان';
    if (area.contains('karari')) return 'كرري';
    if (area.contains('umbadda') || area.contains('ombadda')) return 'أم بدة';
    if (area.contains('jebel aulia')) return 'جبل أولياء';
    if (area.contains('sharq an nil') || area.contains('east nile')) {
      return 'شرق النيل';
    }
    if (area.contains('wad madani') || area.contains('wad medani')) {
      return 'ود مدني';
    }
    if (area.contains('port sudan')) return 'بورتسودان';
    if (area.contains('kassala')) return 'كسلا';
    if (area.contains('nyala')) return 'نيالا';
    if (area.contains('el fasher') || area.contains('al fashir')) {
      return 'الفاشر';
    }
    if (area.contains('al ubayyid') || area.contains('el obeid')) {
      return 'الأبيض';
    }

    for (var l in localities) {
      if (localityArea.contains(l) || l.contains(localityArea)) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.my_location,
      iconColor: AppColors.primary,
      title:
          AppLocalizations.of(context)!.updateMyLocation,
      subtitle: _isLoading
          ? (AppLocalizations.of(context)!.updatingNow)
          : (AppLocalizations.of(context)!.captureYourCurrentLocationForThe),
      trailing: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: _isLoading
          ? null
          : () async {
              bool serviceEnabled;
              LocationPermission permission;

              serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (!serviceEnabled) {
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!.pleaseEnableLocationServices)),
                  );
                }
                return;
              }

              permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied) {
                  return;
                }
              }

              if (permission == LocationPermission.deniedForever) {
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!.locationPermissionsArePermanentlyDenied)),
                  );
                }
                return;
              }

              setState(() {
                _isLoading = true;
              });

              try {
                Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high);

                String? state;
                String? locality;

                try {
                  List<Placemark> placemarks = await placemarkFromCoordinates(
                      position.latitude, position.longitude);
                  if (placemarks.isNotEmpty) {
                    final placemark = placemarks.first;
                    state = _matchState(placemark.administrativeArea ?? '');
                    if (state != null) {
                      locality = _matchLocality(
                          placemark.locality ??
                              placemark.subAdministrativeArea ??
                              '',
                          state);
                    }
                  }
                } catch (geocodingError) {
                  debugPrint(
                      'Error reverse geocoding location: $geocodingError');
                  // Continue without state/locality if geocoding fails
                }

                bool success = await widget.auth.updateLocation(
                  position.latitude,
                  position.longitude,
                  state: state,
                  locality: locality,
                );
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                        content: Text(success
                            ? (AppLocalizations.of(context)!.locationUpdatedSuccessfully)
                            : (AppLocalizations.of(context)!.errorUpdatingLocation))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)!.failedToCaptureLocation)),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
    );
  }
}
