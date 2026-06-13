import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final BoxShape shape;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.border,
    this.shape = BoxShape.rectangle,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGlassEnabled = context.watch<ThemeProvider>().isGlassmorphismEnabled;
    
    final baseColor = color ?? (isDark ? Colors.white : Colors.black);

    final resolvedBorderRadius = shape == BoxShape.circle 
      ? null 
      : (borderRadius ?? BorderRadius.circular(16));

    final innerContainer = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: resolvedBorderRadius,
        color: isGlassEnabled ? null : (color ?? Theme.of(context).cardColor),
        gradient: isGlassEnabled ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(opacity + 0.15),
            baseColor.withOpacity((opacity - 0.05).clamp(0.0, 1.0)),
          ],
        ) : null,
        border: border ??
            Border.all(
              color: isGlassEnabled 
                  ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.5)) 
                  : baseColor.withOpacity(isDark ? 0.1 : 0.05),
              width: 1.5,
            ),
      ),
      child: child,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: isGlassEnabled
          ? ClipRRect(
              borderRadius: resolvedBorderRadius ?? BorderRadius.zero,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: innerContainer,
              ),
            )
          : innerContainer,
    );
  }
}
