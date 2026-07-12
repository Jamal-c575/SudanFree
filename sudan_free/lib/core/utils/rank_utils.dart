import 'package:flutter/material.dart';
import 'package:sudan_free/l10n/generated/app_localizations.dart';

class RankUtils {
  /// Calculate total stars from rating and reviews count
  static int calculateTotalStars(double rating, int reviewsCount) {
    return (rating * reviewsCount).round();
  }

  /// Get rank info based on total stars (returns null if less than 100 stars)
  static RankInfo? getRankInfo(BuildContext context, int totalStars, String locale) {
    // No rank for users with less than 100 stars (new users)
    if (totalStars < 100) {
      return null;
    }

    if (totalStars >= 1000) {
      return RankInfo(
        title: AppLocalizations.of(context)!.legend,
        color: const Color(0xFFFFD700), // Gold
        icon: Icons.emoji_events,
        level: 6,
        nextMilestone: null, // Max level
        progress: 1.0,
      );
    } else if (totalStars >= 800) {
      return RankInfo(
        title: AppLocalizations.of(context)!.master,
        color: const Color(0xFF9C27B0), // Purple
        icon: Icons.workspace_premium,
        level: 5,
        nextMilestone: 1000,
        progress: (totalStars - 800) / 200,
      );
    } else if (totalStars >= 500) {
      return RankInfo(
        title: AppLocalizations.of(context)!.distinguished,
        color: const Color(0xFF2196F3), // Blue
        icon: Icons.military_tech,
        level: 4,
        nextMilestone: 800,
        progress: (totalStars - 500) / 300,
      );
    } else if (totalStars >= 300) {
      return RankInfo(
        title: AppLocalizations.of(context)!.expert,
        color: const Color(0xFF4CAF50), // Green
        icon: Icons.handshake_rounded,
        level: 3,
        nextMilestone: 500,
        progress: (totalStars - 300) / 200,
      );
    } else {
      // 100-299
      return RankInfo(
        title: AppLocalizations.of(context)!.professional,
        color: const Color(0xFFFF9800), // Orange
        icon: Icons.star,
        level: 2,
        nextMilestone: 300,
        progress: (totalStars - 100) / 200,
      );
    }
  }

  /// Get a motivational message based on progress
  static String getNextMilestoneMessage(BuildContext context, int totalStars, int? nextMilestone, String locale) {
    if (nextMilestone == null) {
      return AppLocalizations.of(context)!.youreAtTheTopKeepExcelling;
    }

    final remaining = nextMilestone - totalStars;
    return locale == 'ar'
        ? 'باقي $remaining ⭐ للرتبة التالية'
        : '$remaining ⭐ to next rank';
  }
}

class RankInfo {
  final String title;
  final Color color;
  final IconData icon;
  final int level;
  final int? nextMilestone;
  final double progress;

  RankInfo({
    required this.title,
    required this.color,
    required this.icon,
    required this.level,
    required this.nextMilestone,
    required this.progress,
  });
}
