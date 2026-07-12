import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/glass_card.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';

/// صفحة عن التطبيق - About Screen
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.about,
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
                const Icon(Icons.handshake, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.sudanFree,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.thePremierSudaneseFreelancePlatform,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // What is Sudan Free
          _SectionTitle(
            icon: Icons.info_outline,
            title: AppLocalizations.of(context)!.aboutTheApp,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.connect_without_contact,
            iconColor: AppColors.primary,
            text: AppLocalizations.of(context)!.sudanFreeIsTheFirstIntegrated,
          ),

          const SizedBox(height: 24),

          // For Workers
          _SectionTitle(
            icon: Icons.engineering,
            title: AppLocalizations.of(context)!.forServiceProviders,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.storefront,
            iconColor: Colors.blue,
            text: AppLocalizations.of(context)!.dedicatedSpaceToShowcaseYourSkillsn,
          ),

          const SizedBox(height: 24),

          // For Clients
          _SectionTitle(
            icon: Icons.person_search,
            title: AppLocalizations.of(context)!.forClients1,
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.search,
            iconColor: Colors.teal,
            text: AppLocalizations.of(context)!.smartSearchForTheRightProvider,
          ),

          const SizedBox(height: 24),

          // Platform Features
          _SectionTitle(
            icon: Icons.star,
            title: AppLocalizations.of(context)!.premiumFeatures,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.map,
            iconColor: Colors.amber,
            text: AppLocalizations.of(context)!.mapExplorerAFastLocallyCached,
          ),
          _AboutCard(
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
            text: AppLocalizations.of(context)!.unifiedFavoritesOnePlaceToSave,
          ),

          const SizedBox(height: 24),

          // Community Vision
          _SectionTitle(
            icon: Icons.public,
            title: AppLocalizations.of(context)!.ourVision,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _AboutCard(
            icon: Icons.groups,
            iconColor: Colors.orange,
            text: AppLocalizations.of(context)!.weStriveToBuildACohesive,
          ),

          const SizedBox(height: 32),
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

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _AboutCard({
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
