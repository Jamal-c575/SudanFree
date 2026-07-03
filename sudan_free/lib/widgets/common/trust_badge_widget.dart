import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/trust_service.dart';
import 'glass_container.dart';

class TrustBadgeWidget extends StatelessWidget {
  final TrustBadge badge;
  final bool isAr;
  final bool compact;

  const TrustBadgeWidget({
    super.key,
    required this.badge,
    required this.isAr,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: badge.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: badge.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(badge.icon, size: 10, color: badge.color),
            const SizedBox(width: 2),
            Text(
              isAr ? badge.labelAr : badge.labelEn,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badge.color,
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: badge.color.withValues(alpha: 0.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 14, color: badge.color),
          const SizedBox(width: 4),
          Text(
            isAr ? badge.labelAr : badge.labelEn,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badge.color,
            ),
          ),
        ],
      ),
    );
  }
}

class TrustScoreMeter extends StatelessWidget {
  final UserModel user;
  const TrustScoreMeter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final score = TrustService.calculateTrustScore(user);
    final color = TrustService.getScoreColor(score);
    final badge = TrustService.getPrimaryBadge(user);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety, color: color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      isAr ? 'مؤشر الثقة' : 'Trust Score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isAr 
                    ? 'هذا المؤشر يقيس تفاعل الحرفي وتقييماته لضمان أمانك.'
                    : 'This score measures the freelancer interaction to ensure your safety.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 8),
                  TrustBadgeWidget(badge: badge, isAr: isAr),
                ]
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Circular Meter
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

