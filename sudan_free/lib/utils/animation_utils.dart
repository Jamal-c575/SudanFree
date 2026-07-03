import 'package:flutter/material.dart';

class AnimationUtils {
  // Spring physics curve for Telegram-like bouncy but firm feel
  static const Curve springCurve = Cubic(0.175, 0.885, 0.32, 1.15); // Slightly bouncy easeOutBack
  static const Curve smoothCurve = Curves.fastLinearToSlowEaseIn;

  // Standard duration for most micro-interactions
  static const Duration microInteractionDuration = Duration(milliseconds: 200);
  
  // Standard duration for page transitions
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  // Telegram-style page transition (Slide from right with slight scale)
  static Route createPremiumRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: pageTransitionDuration,
      reverseTransitionDuration: pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: smoothCurve));
            
        var scaleTween = Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: smoothCurve));

        return SlideTransition(
          position: animation.drive(tween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  // Fade transition for dialogs or lightweight overlays
  static Route createFadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }
}
