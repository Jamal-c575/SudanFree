import 'package:flutter/material.dart';

class PulsingMarker extends StatefulWidget {
  final Widget child;
  final Color pulseColor;
  final bool isPulsing;
  final double baseSize;
  final double pulseSize;

  const PulsingMarker({
    super.key,
    required this.child,
    required this.pulseColor,
    this.isPulsing = true,
    this.baseSize = 50.0,
    this.pulseSize = 70.0,
  });

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isPulsing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsingMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing != oldWidget.isPulsing) {
      if (widget.isPulsing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPulsing) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.baseSize + ((widget.pulseSize - widget.baseSize) * _animation.value),
              height: widget.baseSize + ((widget.pulseSize - widget.baseSize) * _animation.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.pulseColor.withValues(alpha: 1.0 - _animation.value),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
