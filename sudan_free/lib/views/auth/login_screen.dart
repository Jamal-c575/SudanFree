import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/premium_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
import 'register_screen.dart';
import '../settings/privacy_policy_screen.dart';
import '../../widgets/common/premium_glass_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../utils/animation_utils.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/generated/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBanDialogShowing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // مسح كل الـ navigation stack بالكامل لإتاحة
      // Consumer في app.dart يعيد توجيه المستخدم تلقائياً
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else if (!success && mounted) {
      final error = authProvider.errorMessage ?? 'Login failed';
      if (error.startsWith('DEVICE_BANNED:')) {
        _showBanDialog(error.replaceFirst('DEVICE_BANNED:', ''));
      } else {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showForgotPasswordDialog(String locale) {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.resetPassword,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.enterYourEmailAndWeWill,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.email,
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: Text(AppLocalizations.of(context)!.send),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              final authProvider = context.read<AuthProvider>();
              final success = await authProvider.resetPassword(email);
              if (mounted) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (AppLocalizations.of(context)!
                              .resetLinkSentToYourEmail)
                          : (authProvider.errorMessage ?? 'Failed'),
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showBanDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block, color: Colors.red, size: 48),
        title: const Text('تم إيقاف حسابك',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'عذراً، تم إيقاف حسابك من قبل الإدارة للسبب التالي:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              reason.isEmpty ? 'مخالفة الشروط والأحكام' : reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'إذا كنت تعتقد أن هذا حدث بالخطأ، يرجى التواصل مع الدعم الفني لحل المشكلة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('تواصل معنا'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final doc = await FirebaseFirestore.instance
                    .collection('settings')
                    .doc('app_settings')
                    .get();
                final whatsapp =
                    doc.data()?['whatsapp'] ?? 'https://wa.me/249900578357';
                final url = Uri.parse(whatsapp);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                final url = Uri.parse('https://wa.me/249900578357');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => _isBanDialogShowing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if user was kicked out in real-time
    if (authProvider.status == AuthStatus.error &&
        authProvider.errorMessage != null) {
      final err = authProvider.errorMessage!;
      if (err.startsWith('BANNED:') || err.startsWith('DEVICE_BANNED:')) {
        if (!_isBanDialogShowing) {
          _isBanDialogShowing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showBanDialog(err
                .replaceFirst('BANNED:', '')
                .replaceFirst('DEVICE_BANNED:', ''));
          });
        }
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                    AppColors.primary.withValues(alpha: 0.2)
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFE2E8F0),
                    AppColors.primary.withValues(alpha: 0.1)
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PremiumGlassCard(
                blur: 30,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Language Toggle (Top Right)
                      Align(
                        alignment: locale == 'ar'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              context.read<LocaleProvider>().toggleLocale(),
                          icon: const Icon(Icons.language, size: 20),
                          label:
                              Text(AppLocalizations.of(context)!.dynamicString),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Logo and Title
                      Center(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/app_logo.jpg',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.appName,
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.platformSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Login Form
                      Text(
                        l10n.login,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),

                      const SizedBox(height: 24),

                      // Email Field
                      CustomTextField(
                        label: l10n.email,
                        hint: 'example@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .emailIsRequired;
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return AppLocalizations.of(context)!.invalidEmail;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Field
                      PasswordTextField(
                        label: l10n.password,
                        hint: '********',
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .passwordIsRequired;
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context)!
                                .passwordTooShort;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),

                      // Forgot Password
                      Align(
                        alignment: locale == 'ar'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(locale),
                          child: Text(l10n.forgotPassword),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      PremiumButton(
                        label: l10n.login,
                        isLoading: isLoading,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _handleLogin();
                        },
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'أو',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Login Button
                      _GoogleSignInButton(
                        isLoading: isLoading,
                        locale: locale,
                        onPressed: () async {
                          final authProvider = context.read<AuthProvider>();
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          final success = await authProvider.signInWithGoogle();

                          if (success && context.mounted) {
                            // مسح كل الـ navigation stack بالكامل
                            Navigator.of(context)
                                .pushNamedAndRemoveUntil('/', (route) => false);
                          } else if (authProvider.errorMessage != null &&
                              context.mounted) {
                            final error = authProvider.errorMessage!;
                            if (error.startsWith('DEVICE_BANNED:')) {
                              _showBanDialog(
                                  error.replaceFirst('DEVICE_BANNED:', ''));
                            } else {
                              String friendlyError = error;
                              if (error.contains('network_error') ||
                                  error.contains('ApiException: 7')) {
                                friendlyError = AppLocalizations.of(context)!
                                    .noInternetConnectionPleaseCheckYour;
                              } else if (error.contains('sign_in_canceled') ||
                                  error.contains('canceled')) {
                                friendlyError = AppLocalizations.of(context)!
                                    .signInCanceled;
                              }
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(friendlyError),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Facebook Login Button
                      _FacebookSignInButton(
                        isLoading: isLoading,
                        locale: locale,
                        onPressed: () {
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .facebookAuthenticationWillBeActivatedSoon,
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Terms and Conditions Link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              AnimationUtils.createPremiumRoute(const PrivacyPolicyScreen()),
                            );
                          },
                          child: Text(
                            l10n.privacyPolicy,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.noAccount,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                AnimationUtils.createPremiumRoute(const RegisterScreen()),
                              );
                            },
                            child: Text(l10n.signup),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                    ],
                  ).animate().fade(duration: const Duration(milliseconds: 600)).slideY(begin: 0.1, curve: AnimationUtils.smoothCurve),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Google Sign-In Button Widget
class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final String locale;
  final VoidCallback onPressed;

  const _GoogleSignInButton({
    required this.isLoading,
    required this.locale,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumGlassCard(
      blur: 15,
      opacity: isDark ? 0.2 : 0.05,
      color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google 'G' icon built from colored arcs
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CustomPaint(painter: _GoogleIconPainter()),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context)!.continueWithGoogle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the Google 'G' logo colors
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw colored quarters
    final colors = [
      (const Color(0xFF4285F4), -30.0, 120.0), // Blue
      (const Color(0xFF34A853), 90.0, 90.0), // Green
      (const Color(0xFFFBBC05), 180.0, 90.0), // Yellow
      (const Color(0xFFEA4335), 270.0, 120.0), // Red
    ];

    for (final (color, start, sweep) in colors) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect.deflate(size.width * 0.11),
        start * 3.14159 / 180,
        sweep * 3.14159 / 180,
        false,
        paint,
      );
    }

    // White center circle to create ring effect
    canvas.drawCircle(
      center,
      radius * 0.52,
      Paint()..color = Colors.white,
    );

    // Draw the 'G' bar (horizontal line into center)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.72, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Facebook Sign-In Button Widget
class _FacebookSignInButton extends StatelessWidget {
  final bool isLoading;
  final String locale;
  final VoidCallback onPressed;

  const _FacebookSignInButton({
    required this.isLoading,
    required this.locale,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.7,
      child: PremiumGlassCard(
        blur: 15,
        opacity: 0.2,
        color: const Color(0xFF1877F2), // Facebook Blue
        borderRadius: BorderRadius.circular(12),
        border: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.facebook, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.continueWithFacebook,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
