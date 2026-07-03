import 'package:flutter/material.dart';

/// A smooth page transition that combines Fade + Slide for a premium feel.
/// Drop-in replacement for MaterialPageRoute.
class SmoothRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final fadeAnim = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            final slideAnim = Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );
            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: child,
              ),
            );
          },
        );
}

/// A smooth bottom-to-top slide route (for sheets / modals pushed as pages).
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
        );
}
