import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../utils/animation_utils.dart';

enum JhomeButtonType { primary, outlined, glass, text }

/// JhomeButton: The unified button component for the Jhome Design System.
/// Features a bouncy scale animation on press to mimic HarmonyOS fluid mechanics.
class JhomeButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final JhomeButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final Color? color;
  final Color? textColor;

  const JhomeButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.type = JhomeButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 54.0,
    this.color,
    this.textColor,
  });

  @override
  State<JhomeButton> createState() => _JhomeButtonState();
}

class _JhomeButtonState extends State<JhomeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationUtils.springCurve,
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getBgColor() {
      if (widget.color != null) return widget.color!;
      switch (widget.type) {
        case JhomeButtonType.primary:
          return AppColors.primary;
        case JhomeButtonType.outlined:
        case JhomeButtonType.text:
          return Colors.transparent;
        case JhomeButtonType.glass:
          return (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.1);
      }
    }

    Color getTxtColor() {
      if (widget.textColor != null) return widget.textColor!;
      switch (widget.type) {
        case JhomeButtonType.primary:
          return Colors.white;
        case JhomeButtonType.outlined:
        case JhomeButtonType.text:
        case JhomeButtonType.glass:
          return AppColors.primary;
      }
    }

    Border? getBorder() {
      if (widget.type == JhomeButtonType.outlined) {
        return Border.all(color: widget.color ?? AppColors.primary, width: 1.5);
      }
      return null;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Opacity(
          opacity: widget.onPressed == null ? 0.5 : 1.0,
          child: Container(
            width: widget.isFullWidth ? double.infinity : widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: getBgColor(),
              borderRadius: BorderRadius.circular(12.0),
              border: getBorder(),
              boxShadow: widget.type == JhomeButtonType.primary
                  ? [
                      BoxShadow(
                        color: getBgColor().withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: getTxtColor(),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: widget.isFullWidth
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: getTxtColor(), size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: getTxtColor(),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
