import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/constants/app_colors.dart';

class TrustBadge {
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final Color color;

  const TrustBadge({
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    required this.color,
  });
}

class TrustService {
  /// يحسب نسبة الثقة للمستخدم (0-100) محلياً بدون تحميل السيرفر
  static int calculateTrustScore(UserModel user) {
    if (user.role == UserRole.client) return 0; // لا نحسب للعملاء

    double score = 0;

    // 1. توثيق الهوية (الأهمية: عالية جداً)
    if (user.isVerified) score += 30;

    // 2. التقييمات (الأهمية: عالية)
    if (user.rating > 0) {
      // 5 نجوم = 25 نقطة، 4 نجوم = 20 نقطة...
      score += (user.rating * 5);
      
      // مكافأة لعدد المراجعات (دليل على كثرة العمل)
      if (user.reviewsCount > 50) {
        score += 15;
      } else if (user.reviewsCount > 20) {
        score += 10;
      } else if (user.reviewsCount > 5) {
        score += 5;
      }
    }

    // 3. اكتمال الملف الشخصي (الأهمية: متوسطة)
    if (user.bio != null && user.bio!.length > 20) score += 5;
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) score += 5;
    if (user.portfolioImages.isNotEmpty || user.portfolioVideos.isNotEmpty) score += 10;

    // 4. العمل المكتمل
    if (user.completedJobs > 10) score += 10;

    // 5. الانضباط والمخالفات (خصم قوي)
    if (user.negativeReports > 0) {
      score -= (user.negativeReports * 20); // كل تقرير سلبي يخصم 20 نقطة
    }

    return score.clamp(0, 100).toInt();
  }

  /// يحدد الشارة المناسبة بناءً على النتيجة
  static TrustBadge? getPrimaryBadge(UserModel user) {
    final score = calculateTrustScore(user);

    if (user.isVerified && score >= 90) {
      return const TrustBadge(
        labelAr: 'نخبة',
        labelEn: 'Elite',
        icon: Icons.verified_user,
        color: Colors.amber, // لون ذهبي
      );
    } else if (user.isVerified && score >= 75) {
      return const TrustBadge(
        labelAr: 'موثوق',
        labelEn: 'Trusted',
        icon: Icons.shield,
        color: Colors.blueAccent, // لون الثقة
      );
    } else if (score >= 60) {
      return const TrustBadge(
        labelAr: 'مجتهد',
        labelEn: 'Active',
        icon: Icons.trending_up,
        color: Colors.green, // نشيط
      );
    } else if (user.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))) {
      return const TrustBadge(
        labelAr: 'جديد',
        labelEn: 'New',
        icon: Icons.new_releases,
        color: Colors.purpleAccent, // جديد في المنصة
      );
    }

    return null; // لا توجد شارة خاصة
  }

  /// إرجاع اللون المناسب لدائرة تقييم الثقة في البروفايل
  static Color getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
