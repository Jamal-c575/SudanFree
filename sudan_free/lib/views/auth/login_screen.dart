import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
import 'register_screen.dart';
import '../settings/privacy_policy_screen.dart';

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
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } else if (!success && mounted) {
      final error = authProvider.errorMessage ?? 'Login failed';
      if (error.startsWith('DEVICE_BANNED:')) {
        _showBanDialog(error.replaceFirst('DEVICE_BANNED:', ''));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showBanDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block, color: Colors.red, size: 48),
        title: const Text('تم حظر هذا الجهاز', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
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
                'إذا كنت قد اشتريت هذا الهاتف مؤخراً وليس لديك علاقة بالاحتيال السابق، يرجى التواصل معنا لحل المشكلة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Language Toggle (Top Right)
                Align(
                  alignment: locale == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                    icon: const Icon(Icons.language, size: 20),
                    label: Text(locale == 'ar' ? 'English' : 'العربية'),
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
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.platformSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                      return locale == 'ar' ? 'البريد الإلكتروني مطلوب' : 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return locale == 'ar' ? 'بريد إلكتروني غير صالح' : 'Invalid email';
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
                      return locale == 'ar' ? 'كلمة المرور مطلوبة' : 'Password is required';
                    }
                    if (value.length < 6) {
                      return locale == 'ar' ? 'كلمة المرور قصيرة جداً' : 'Password too short';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Forgot Password
                Align(
                  alignment: locale == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to forgot password
                    },
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Login Button
                GradientButton(
                  text: l10n.login,
                  isLoading: isLoading,
                  onPressed: _handleLogin,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final success = await authProvider.signInWithGoogle();
                    
                    if (success && context.mounted) {
                       if (Navigator.canPop(context)) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    } else if (authProvider.errorMessage != null && context.mounted) {
                      final error = authProvider.errorMessage!;
                      if (error.startsWith('DEVICE_BANNED:')) {
                        _showBanDialog(error.replaceFirst('DEVICE_BANNED:', ''));
                      } else {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(error),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Facebook Login Button
                _FacebookSignInButton(
                  isLoading: isLoading,
                  locale: locale,
                  onPressed: () {
                    // TODO: Implement Facebook login
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(locale == 'ar' 
                            ? 'قريباً - تسجيل Facebook' 
                            : 'Coming soon - Facebook login'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),

                // Terms and Conditions Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text(l10n.signup),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
              ],
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Modern Google Icon replacement (using text/shape if asset not available)
                const Icon(Icons.g_mobiledata, size: 32, color: Colors.blue), // Placeholder for logo
                const SizedBox(width: 8),
                Text(
                  locale == 'ar' ? 'المتابعة باستخدام Google' : 'Continue with Google',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.facebook, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  locale == 'ar' ? 'المتابعة باستخدام Facebook' : 'Continue with Facebook',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
