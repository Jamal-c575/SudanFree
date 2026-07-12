import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../utils/animation_utils.dart';
import 'package:sudan_free/utils/app_haptics.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  Future<void> _startAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    AppHaptics.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/static_handshake.png',
              width: 150,
              height: 150,
              color: Colors.white,
            ).animate()
              .fade(duration: const Duration(milliseconds: 800))
              .scale(begin: const Offset(0.8, 0.8), curve: AnimationUtils.springCurve)
              .shake(hz: 2, curve: Curves.easeInOut, delay: const Duration(milliseconds: 800)),
            const SizedBox(height: 40),
            const Text(
              'سودان فري',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 4),
                      blurRadius: 10),
                ],
              ),
            ).animate().fade(delay: const Duration(milliseconds: 400)).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'SUDAN FREE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 4.0,
              ),
            ).animate().fade(delay: const Duration(milliseconds: 600)).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw stylized hands to simulate the 3D SVG layers
class HandPainter extends CustomPainter {
  final bool isRightHand;

  HandPainter({required this.isRightHand});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    if (isRightHand) {
      // Right hand (darker for depth)
      paint.color = Colors.white.withValues(alpha: 0.7);

      final path = Path();
      // Draw wrist and palm
      path.moveTo(size.width * 0.8, size.height);
      path.lineTo(size.width * 0.4, size.height * 0.6);
      path.quadraticBezierTo(size.width * 0.2, size.height * 0.4,
          size.width * 0.4, size.height * 0.2);
      path.quadraticBezierTo(size.width * 0.6, size.height * 0.1,
          size.width * 0.8, size.height * 0.3);
      path.lineTo(size.width, size.height * 0.5);
      path.lineTo(size.width * 0.8, size.height);

      canvas.drawPath(path, paint);

      // Add some shading
      paint.color = Colors.black.withValues(alpha: 0.1);
      canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.4), 15, paint);
    } else {
      // Left hand fingers overlapping (bright white)
      paint.color = Colors.white;

      final path = Path();
      // Draw wrist and overlapping fingers
      path.moveTo(size.width * 0.2, 0);
      path.lineTo(size.width * 0.6, size.height * 0.4);
      path.quadraticBezierTo(size.width * 0.8, size.height * 0.6,
          size.width * 0.6, size.height * 0.8);
      path.quadraticBezierTo(size.width * 0.4, size.height * 0.9,
          size.width * 0.2, size.height * 0.7);
      path.lineTo(0, size.height * 0.5);
      path.lineTo(size.width * 0.2, 0);

      canvas.drawPath(path, paint);

      // Draw finger separations to create depth
      paint.color = AppColors.primary.withValues(alpha: 0.3);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3.0;

      canvas.drawLine(
        Offset(size.width * 0.4, size.height * 0.4),
        Offset(size.width * 0.7, size.height * 0.5),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.35, size.height * 0.55),
        Offset(size.width * 0.65, size.height * 0.65),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.3, size.height * 0.7),
        Offset(size.width * 0.55, size.height * 0.8),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
