import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/common/premium_glass_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/premium_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../utils/animation_utils.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/privacy_policy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final locale = context.read<LocaleProvider>().locale.languageCode;
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.termsOfUseAndPrivacy,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!.byClickingAgreeYouConfirmThat),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
            child: Text(AppLocalizations.of(context)!.readTerms),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: ShimmerLoading(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              );

              final success = await authProvider.signUpWithEmail(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );

              if (mounted) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading overlay
                }
              }

              if (success && mounted) {
                // مسح كل الـ stack - app.dart سيعرض ProfileSetupScreen تلقائياً
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              } else if (!success && mounted) {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        authProvider.errorMessage ?? 'Registration failed'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.agree),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale.languageCode;
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.signup),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                const SizedBox(height: 24),

                // Welcome Text
                Text(
                  AppLocalizations.of(context)!.welcomeToSudanfree,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.createYourAccountToStartYour,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 32),

                // Email Field
                CustomTextField(
                  label: l10n.email,
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.emailIsRequired;
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
                  label: AppStrings.get(AppStrings.password, locale),
                  hint: AppLocalizations.of(context)!.enterYourPassword,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.passwordIsRequired;
                    }
                    if (value.length < 6) {
                      return AppLocalizations.of(context)!.passwordMustBeAtLeast6;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                PasswordTextField(
                  label:
                      AppLocalizations.of(context)!.confirmPassword,
                  hint: AppLocalizations.of(context)!.reenterPassword,
                  controller: _confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.confirmPasswordIsRequired;
                    }
                    if (value != _passwordController.text) {
                      return AppLocalizations.of(context)!.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Register Button
                PremiumButton(
                  label: AppStrings.get(AppStrings.signup, locale),
                  isLoading: isLoading,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _handleRegister();
                  },
                ),

                const SizedBox(height: 24),

                // Terms and Conditions
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      AnimationUtils.createPremiumRoute(const PrivacyPolicyScreen()),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.byRegisteringYouAgreeToThe,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.get(AppStrings.haveAccount, locale),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Text(AppStrings.get(AppStrings.login, locale)),
                    ),
                  ],
                ),
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
