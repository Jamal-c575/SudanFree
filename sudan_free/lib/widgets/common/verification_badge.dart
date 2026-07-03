import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/trust_service.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';

/// شارة تحقق متعددة المستويات — تعرض مستوى ثقة المستخدم بصرياً
///
/// المستويات:
/// - 🟢 Level 1: Phone Verified → علامة صح خضراء
/// - 🔵 Level 2: Identity Verified → شارة زرقاء
/// - 🟡 Level 3: Top Pro → شارة ذهبية مع تأثير pulse
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;

  const VerificationBadge({
    super.key,
    required this.isVerified,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    return _IdentityBadge(size: size);
  }
}

/// شارة تحقق متقدمة تعتمد على بيانات المستخدم الكاملة
class SmartVerificationBadge extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showTooltip;

  const SmartVerificationBadge({
    super.key,
    required this.user,
    this.size = 18.0,
    this.showTooltip = true,
  });

  _BadgeLevel get _level {
    // Level 4 — Premium (الحساب المميز / المتجر الملكي)
    if (user.isPremium) {
      return _BadgeLevel.premium;
    }
    // Level 3 — Top Pro: موثق + تقييم 4.5+ وأكثر من 20 عمل مكتمل
    if (user.isVerified && user.rating >= 4.5 && user.completedJobs >= 20) {
      return _BadgeLevel.topPro;
    }
    // Level 2 — Identity Verified: تم التحقق من الهوية
    if (user.isVerified) {
      return _BadgeLevel.identityVerified;
    }
    // Level 1 — Phone Verified: يملك رقم هاتف مُسجل
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      return _BadgeLevel.phoneVerified;
    }
    return _BadgeLevel.none;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (level == _BadgeLevel.none) return const SizedBox.shrink();

    final badge = _buildBadge(level);

    if (!showTooltip) return badge;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Tooltip(
      message: _getTooltipText(level, context),
      preferBelow: false,
      child: badge,
    );
  }

  Widget _buildBadge(_BadgeLevel level) {
    switch (level) {
      case _BadgeLevel.premium:
        return _PremiumBadge(size: size);
      case _BadgeLevel.topPro:
        return _TopProBadge(size: size);
      case _BadgeLevel.identityVerified:
        return _IdentityBadge(size: size);
      case _BadgeLevel.phoneVerified:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: size * 0.85,
          ),
        );
      case _BadgeLevel.none:
        return const SizedBox.shrink();
    }
  }

  String _getTooltipText(_BadgeLevel level, BuildContext context) {
    switch (level) {
      case _BadgeLevel.premium:
        return AppLocalizations.of(context)!.premiumVerifiedRoyalAccount;
      case _BadgeLevel.topPro:
        return AppLocalizations.of(context)!.topProVerifiedWithExcellentRatings;
      case _BadgeLevel.identityVerified:
        return AppLocalizations.of(context)!.identityVerified;
      case _BadgeLevel.phoneVerified:
        return AppLocalizations.of(context)!.phoneVerified;
      case _BadgeLevel.none:
        return '';
    }
  }
}

/// شارة Top Pro مع تأثير نبض ذهبي متحرك
class _TopProBadge extends StatefulWidget {
  final double size;
  const _TopProBadge({required this.size});

  @override
  State<_TopProBadge> createState() => _TopProBadgeState();
}

class _TopProBadgeState extends State<_TopProBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sudanGold
                      .withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: widget.size * 0.6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(
              Icons.verified,
              color: AppColors.sudanGold,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

/// شارة حساب مميز - شكل ملكي وتاج
class _PremiumBadge extends StatelessWidget {
  final double size;
  const _PremiumBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.verified,
            color: const Color(0xFFFFD700), // Gold
            size: size,
          ),
          Positioned(
            bottom: size * 0.1,
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: size * 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة توثيق الهوية - تصميم زجاجي لامع وفريد
class _IdentityBadge extends StatelessWidget {
  final double size;
  const _IdentityBadge({required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Container(
        width: size * 1.15,
        height: size * 1.15,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4AC29A), // Mint Green
              Color(0xFFBDFFF3), // Soft Cyan
              Color(0xFF007AFF), // iOS Blue
            ],
            stops: [0.0, 0.4, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.4),
              blurRadius: size * 0.5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 2,
              spreadRadius: -1,
              offset: const Offset(-1, -1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.handshake_rounded,
            color: Colors.white,
            size: size * 0.7,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BadgeLevel { none, phoneVerified, identityVerified, topPro, premium }

/// شريط نقاط السمعة الدائري
class ReputationScoreWidget extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showLabel;

  const ReputationScoreWidget({
    super.key,
    required this.user,
    this.size = 56.0,
    this.showLabel = true,
  });

  /// حساب نقاط السمعة (0 — 100)
  int get _score {
    return TrustService.calculateTrustScore(user);
  }

  Color _scoreColor(int score) {
    return TrustService.getScoreColor(score);
  }

  String _scoreLabel(int score, BuildContext context) {
    if (score >= 90) return AppLocalizations.of(context)!.exceptional;
    if (score >= 80) return AppLocalizations.of(context)!.excellent;
    if (score >= 60) return AppLocalizations.of(context)!.veryGood;
    if (score >= 40) return AppLocalizations.of(context)!.good;
    return AppLocalizations.of(context)!.starter;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final color = _scoreColor(score);
    final label = _scoreLabel(score, context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 3.5,
                      color: color.withValues(alpha: 0.15),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 3.5,
                      color: color,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Score number
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: score.toInt()),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Text(
                        val.toString(),
                        style: TextStyle(
                          fontSize: size * 0.28,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

class SmartVerificationBadgeAsync extends StatelessWidget {
  final String userId;
  final double size;
  final bool showTooltip;

  const SmartVerificationBadgeAsync({
    super.key,
    required this.userId,
    this.size = 18.0,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _fetchUser(context),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return SmartVerificationBadge(
            user: snapshot.data!,
            size: size,
            showTooltip: showTooltip,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<UserModel?> _fetchUser(BuildContext context) async {
    return await FirestoreService().getUser(userId);
  }
}
