import 'package:flutter/material.dart';

class GlassText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool forceHighContrast;

  const GlassText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.forceHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Default text color based on theme
    final baseColor = style?.color ?? (isDark ? Colors.white : Colors.black87);
    
    // Shadow to ensure legibility against complex glass backgrounds
    final List<Shadow> textShadows = [
      Shadow(
        offset: const Offset(0, 1.5),
        blurRadius: 3.0,
        color: isDark 
            ? Colors.black.withValues(alpha: 0.6) 
            : Colors.white.withValues(alpha: 0.8),
      ),
      if (forceHighContrast)
        Shadow(
          offset: const Offset(0, 0),
          blurRadius: 8.0,
          color: isDark 
              ? Colors.black.withValues(alpha: 0.8) 
              : Colors.white.withValues(alpha: 0.9),
        ),
    ];

    final effectiveStyle = style == null 
        ? TextStyle(color: baseColor, shadows: textShadows)
        : style!.copyWith(
            color: baseColor,
            shadows: [
              ...?style!.shadows,
              ...textShadows,
            ],
          );

    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
