import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sudan_free/utils/app_haptics.dart';

class PremiumButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final bool isLoading;
  final double width;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isPrimary = true,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: width,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          AppHaptics.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? AppColors.primary 
              : (isDark ? Colors.white12 : Colors.white),
          foregroundColor: isPrimary 
              ? Colors.white 
              : (isDark ? Colors.white : AppColors.primary),
          elevation: isPrimary ? 8 : 2,
          shadowColor: isPrimary ? AppColors.primary.withValues(alpha: 0.5) : Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(
              color: isDark ? Colors.white24 : AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().scale(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
    );
  }
}
