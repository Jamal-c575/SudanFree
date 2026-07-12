import 'package:flutter/material.dart';
import 'package:sudan_free/core/constants/app_colors.dart';
import 'package:sudan_free/widgets/common/glass_container.dart';

class AiPageGuideWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const AiPageGuideWidget({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<AiPageGuideWidget> createState() => _AiPageGuideWidgetState();
}

class _AiPageGuideWidgetState extends State<AiPageGuideWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.5), // Start from below the screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  void _dismiss() {
    _controller.reverse().then((value) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24, // padding from bottom
      left: 16,
      right: 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss, // tap anywhere to dismiss
            child: SlideTransition(
              position: _offsetAnimation,
              child: GlassContainer(
                enableBlur: true,
                color: Colors.black,
                opacity: 0.7,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '🤝', // Handshake icon for Home
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Home (الذكاء الاصطناعي)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 12),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
