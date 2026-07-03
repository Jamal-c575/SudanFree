import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/glass_card.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.policiesTerms,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [AppColors.primaryLight.withValues(alpha: 0.3), Colors.white],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.gavel, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.usagePoliciesStandards,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 1. Strict Usage Warnings
          _SectionTitle(
            icon: Icons.warning_amber_rounded,
            title: AppLocalizations.of(context)!.importantWarningsTerms,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            text: AppLocalizations.of(context)!.thisAppIsStrictlyForLegitimate,
          ),
          _PolicyCard(
            icon: Icons.block,
            iconColor: Colors.red,
            text: AppLocalizations.of(context)!.postingOffensiveContentOrEngagingIn,
          ),
          _PolicyCard(
            icon: Icons.gavel,
            iconColor: Colors.orange,
            text: AppLocalizations.of(context)!.theAppIsAMediumTo,
          ),

          const SizedBox(height: 24),

          // 2. Safety Advice
          _SectionTitle(
            icon: Icons.health_and_safety,
            title: AppLocalizations.of(context)!.safetyTips,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            icon: Icons.monetization_on,
            iconColor: Colors.green,
            text: AppLocalizations.of(context)!.doNotPayAnyMoneyIn,
          ),
          _PolicyCard(
            icon: Icons.place,
            iconColor: Colors.blue,
            text: AppLocalizations.of(context)!.whenAgreeingToMeetEnsureIt,
          ),
          _PolicyCard(
            icon: Icons.verified_user,
            iconColor: Colors.purple,
            text: AppLocalizations.of(context)!.alwaysDealWithVerifiedAccountsWith,
          ),

          const SizedBox(height: 24),

          // 3. Trust Levels
          _SectionTitle(
            icon: Icons.military_tech,
            title: AppLocalizations.of(context)!.ratingTrustSystem,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            icon: Icons.star,
            iconColor: Colors.amber,
            text: AppLocalizations.of(context)!.starsAwardedInReviewsUpgradeYour,
          ),
          _PolicyCard(
            icon: Icons.balance,
            iconColor: Colors.blue,
            text: AppLocalizations.of(context)!.theRatingSystemPreventsManipulationOnly,
          ),

          const SizedBox(height: 24),

          // 4. Privacy & Data Deletion
          _SectionTitle(
            icon: Icons.privacy_tip,
            title: AppLocalizations.of(context)!.privacyDataDeletion,
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _PolicyCard(
            icon: Icons.phone_android,
            iconColor: Colors.teal,
            text: AppLocalizations.of(context)!.yourPersonalDataNameLocationPhone,
          ),
          _PolicyCard(
            icon: Icons.location_off,
            iconColor: Colors.indigo,
            text: AppLocalizations.of(context)!.mapControlAnyFreelancerOrShop,
          ),
          _PolicyCard(
            icon: Icons.delete_forever,
            iconColor: Colors.deepOrange,
            text: AppLocalizations.of(context)!.youHaveTheRightToRequest,
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              AppLocalizations.of(context)!.usingTheAppMeansYourExplicit,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _PolicyCard({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 12,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ),
          ],
          ),
        ),
      ),
    );
  }
}
