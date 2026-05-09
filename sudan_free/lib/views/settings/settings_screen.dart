import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Added
import 'package:share_plus/share_plus.dart'; // Added
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../safety/safety_tips_screen.dart';
import '../about/about_app_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../settings/admin_dashboard_screen.dart';
import '../auth/identity_verification_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Toggle
          _SettingsTile(
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            title: locale == 'ar' ? 'الوضع الداكن' : 'Dark Mode',
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
              if (auth.user?.role != UserRole.freelancer && auth.user?.role != UserRole.techService) return const SizedBox.shrink();
              final isAvailable = auth.user?.isAvailable ?? true;
              return Column(
                children: [
                  _SettingsTile(
                    icon: Icons.access_time,
                    iconColor: isAvailable ? AppColors.success : AppColors.error,
                    title: locale == 'ar' 
                        ? (isAvailable ? 'متوفر للعمل' : 'غير متوفر حالياً')
                        : (isAvailable ? 'Available for Work' : 'Currently Unavailable'),
                    trailing: Switch(
                      value: isAvailable,
                      onChanged: (value) => auth.toggleAvailability(),
                      activeThumbColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
          
          // Language Toggle
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: locale == 'ar' ? 'العربية' : 'English',
            onTap: () => context.read<LocaleProvider>().toggleLocale(),
            trailing: const Icon(Icons.sync_alt, size: 20, color: AppColors.primary),
          ),

          const SizedBox(height: 8),

          // Identity Verification - NEW
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isVerified = auth.user?.isVerified ?? false;
              return _SettingsTile(
                icon: Icons.handshake,
                iconColor: isVerified ? AppColors.primary : Colors.orange,
                title: locale == 'ar' ? 'توثيق الحساب' : 'Account Verification',
                subtitle: isVerified
                    ? (locale == 'ar' ? 'حسابك موثق — تظهر أيقونة المصافحة بجانب اسمك' : 'Verified — Handshake icon shows beside your name')
                    : (locale == 'ar' ? 'سيتم تفعيله قريباً — أيقونة مصافحة بجانب اسمك' : 'Coming soon — Handshake icon beside your name'),
                trailing: isVerified
                    ? const Icon(Icons.handshake, color: AppColors.primary, size: 22)
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IdentityVerificationScreen()),
                ),
              );
            },
          ),

          // Admin Dashboard - NEW
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.user?.role != UserRole.admin) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.admin_panel_settings,
                    iconColor: Colors.deepPurple,
                    title: locale == 'ar' ? 'لوحة تحكم المشرف' : 'Admin Dashboard',
                    subtitle: locale == 'ar' ? 'إدارة التوثيقات والإحصائيات' : 'Manage verifications & stats',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const Divider(height: 32),
          
          // Safety Tips - NEW
          _SettingsTile(
            icon: Icons.security,
            iconColor: Colors.green,
            title: locale == 'ar' ? '🛡️ نصائح السلامة' : '🛡️ Safety Tips',
            subtitle: locale == 'ar' ? 'احمِ نفسك من الاحتيال' : 'Protect yourself from fraud',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyTipsScreen()),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Notifications Toggle
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final isPushEnabled = auth.user?.notificationSettings['pushEnabled'] ?? true;
              return _SettingsTile(
                icon: isPushEnabled ? Icons.notifications_active : Icons.notifications_off,
                iconColor: isPushEnabled ? AppColors.primary : Colors.grey,
                title: locale == 'ar' ? 'الإشعارات' : 'Notifications',
                subtitle: locale == 'ar' 
                    ? (isPushEnabled ? 'مفعلة' : 'متوقفة') 
                    : (isPushEnabled ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: isPushEnabled,
                  onChanged: (value) => auth.togglePushNotifications(value),
                  activeThumbColor: AppColors.primary,
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // Privacy
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          
          // ... existing code ...
          const Divider(height: 32),
          
          // Connect with Us Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              locale == 'ar' ? 'تواصل معنا' : 'Connect with Us',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          
          // WhatsApp Support
          _SettingsTile(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.green,
            title: locale == 'ar' ? 'واتساب' : 'WhatsApp',
            subtitle: locale == 'ar' ? 'تواصل مع الدعم الفني' : 'Contact Support',
            onTap: () => _launchURL('https://wa.me/249900578357'),
          ),
          
          const SizedBox(height: 8),

          // Facebook
          _SettingsTile(
            icon: Icons.facebook,
            iconColor: Colors.blue[800],
            title: locale == 'ar' ? 'فيسبوك' : 'Facebook',
            onTap: () => _launchURL('https://www.facebook.com/share/18J8UXiEDe/'),
          ),
          
          const SizedBox(height: 8),

          // Telegram
          _SettingsTile(
            icon: Icons.send, // Telegram icon substitute
            iconColor: Colors.blue[400],
            title: locale == 'ar' ? 'تلجرام' : 'Telegram',
            onTap: () => _launchURL('https://t.me/JamalJhome'),
          ),
          
          const SizedBox(height: 8),

          // Website
          _SettingsTile(
            icon: Icons.language,
            iconColor: Colors.purple,
            title: locale == 'ar' ? 'الموقع الإلكتروني' : 'Website',
            onTap: () => _launchURL('https://jamall123.github.io/HOME_WEB/'),
          ),
          
          const SizedBox(height: 8),

          // Share App
          _SettingsTile(
            icon: Icons.share,
            iconColor: Colors.orange,
            title: locale == 'ar' ? 'شارك التطبيق' : 'Share App',
            onTap: () async {
              final text = locale == 'ar' 
                  ? 'جرب تطبيق سودان فري للعثور على فرص عمل ومستقلين موثوقين! حمل التطبيق الآن: https://jamall123.github.io/HOME_WEB/sudan-free.html'
                  : 'Try SudanFree to find jobs and trusted freelancers! Download now: https://jamall123.github.io/HOME_WEB/sudan-free.html';
              // ignore: deprecated_member_use
              await Share.share(text);
            },
          ),

          const Divider(height: 32),
          
          // About
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: AppColors.primary,
            title: locale == 'ar' ? '📱 عن التطبيق' : '📱 About App',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutAppScreen()),
            ),
          ),
          
          const SizedBox(height: 24),

          // Logout Button
          _SettingsTile(
            icon: Icons.logout,
            iconColor: AppColors.error,
            title: l10n.logout,
            onTap: () => _showLogoutDialog(context, locale),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, String locale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locale == 'ar' ? 'ماذا تريد أن تفعل؟' : 'What do you want to do?'),
        content: Text(
          locale == 'ar' 
              ? 'يمكنك تسجيل الخروج والعودة لاحقاً، أو حذف حسابك وبياناتك نهائياً من التطبيق.'
              : 'You can logout and return later, or permanently delete your account and data from the app.',
        ),
        actions: [
          // Row for main choices
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performLogout(context);
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    locale == 'ar' ? 'تسجيل الخروج' : 'Logout', 
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
                    locale == 'ar' ? 'حذف الحساب نهائياً' : 'Delete Account Permanently', 
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
              ),
            ],
          ),
        ],
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
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              locale == 'ar' ? 'طلب حذف الحساب' : 'Delete Account Request',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale == 'ar' 
                      ? 'لأسباب أمنية ولحماية حقوق جميع المستخدمين، يتم مراجعة طلبات الحذف من قبل الإدارة. يرجى ذكر سبب رغبتك في حذف الحساب وسنقوم بتسجيل خروجك مؤقتاً حتى إتمام الحذف.'
                      : 'For security reasons and to protect all users, deletion requests are reviewed by admin. Please state your reason. You will be logged out until the deletion is complete.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: locale == 'ar' ? 'السبب (اختياري ولكن يسرع العملية)' : 'Reason (optional but speeds up the process)',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isLoading ? null : () async {
                  setState(() => isLoading = true);
                  final auth = context.read<AuthProvider>();
                  final success = await auth.requestAccountDeletion(reasonController.text.trim());
                  
                  if (success && context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(locale == 'ar' ? 'تم إرسال طلب الحذف بنجاح' : 'Deletion request sent successfully'),
                      backgroundColor: Colors.green,
                    ));
                    _performLogout(context);
                  } else {
                    setState(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(locale == 'ar' ? 'حدث خطأ، حاول مرة أخرى' : 'Error occurred, try again'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  }
                },
                child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(locale == 'ar' ? 'تأكيد الطلب' : 'Confirm Request', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
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

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _scale = 0.97);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _scale = 1.0);
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? AppColors.primary;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: Theme.of(context).brightness == Brightness.light 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: color),
            ),
            title: Text(widget.title),
            subtitle: widget.subtitle != null ? Text(widget.subtitle!) : null,
            trailing: widget.trailing ?? (widget.onTap != null ? const Icon(Icons.chevron_right) : null),
          ),
        ),
      ),
    );
  }
}
