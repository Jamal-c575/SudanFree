import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final bool border;
  final Color? color;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius,
    this.onTap,
    this.border = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = color ?? (isDark ? Colors.white : Colors.black);
    
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: defaultColor.withValues(alpha: opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: border ? Border.all(
          color: defaultColor.withValues(alpha: isDark ? 0.2 : 0.1),
          width: 1.5,
        ) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: (borderRadius as BorderRadius?) ?? BorderRadius.circular(20),
          splashColor: defaultColor.withValues(alpha: 0.1),
          highlightColor: defaultColor.withValues(alpha: 0.05),
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
