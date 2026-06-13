import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';

class SmartDraggableFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final String heroTag;
  final double initialBottom;
  final double? initialRight;
  final double? initialLeft;
  final String locale;

  const SmartDraggableFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    required this.heroTag,
    required this.initialBottom,
    this.initialRight,
    this.initialLeft,
    required this.locale,
  });

  @override
  State<SmartDraggableFab> createState() => _SmartDraggableFabState();
}

class _SmartDraggableFabState extends State<SmartDraggableFab> with SingleTickerProviderStateMixin {
  late double _x;
  late double _y;
  bool _isInitialized = false;
  bool _isDragging = false;
  bool _isDocked = false;
  Offset _dragDelta = Offset.zero;

  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Slower, smoother animation
    );
    _springController.addListener(() {
      if (_springController.isAnimating) {
        setState(() {
          _x = _springAnimation.value.dx;
          _y = _springAnimation.value.dy;
        });
      }
    });
    _springController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.lightImpact(); // Small bump when hitting the edge
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      final fabWidth = widget.label != null ? 150.0 : 56.0;
      
      if (widget.initialLeft != null) {
        _x = widget.initialLeft!;
      } else if (widget.initialRight != null) {
        _x = size.width - widget.initialRight! - fabWidth;
      } else {
        // Default based on locale
        _x = widget.locale == 'ar' ? 16.0 : size.width - 16.0 - fabWidth;
      }
      
      _y = size.height - widget.initialBottom - 56;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isDocked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = true;
      _dragDelta = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDocked) return;
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;
      _dragDelta = details.delta;

      // Keep within screen bounds
      final size = MediaQuery.of(context).size;
      final widthLimit = widget.label != null && !_isDragging ? 150.0 : 56.0;
      _x = _x.clamp(0.0, size.width - widthLimit);
      _y = _y.clamp(MediaQuery.of(context).padding.top + 16.0, size.height - 56.0 - 16.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDocked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isDragging = false;
      _dragDelta = Offset.zero; // Reset stretch
    });
    _snapToNearestEdge();
  }

  void _snapToNearestEdge() {
    final size = MediaQuery.of(context).size;
    final isCloserToLeft = _x < size.width / 2;
    
    // Snap to 16.0 padding from edge
    final targetX = isCloserToLeft ? 16.0 : size.width - 16.0 - 56.0;
    final targetY = _y.clamp(MediaQuery.of(context).padding.top + 16.0, size.height - 56.0 - 16.0);

    _springAnimation = Tween<Offset>(
      begin: Offset(_x, _y),
      end: Offset(targetX, targetY),
    ).animate(CurvedAnimation(
      parent: _springController, 
      // ElasticOut gives a "jelly/water bouncing" effect when it hits the edge
      curve: const ElasticOutCurve(0.6),
    ));

    _springController.forward(from: 0);
  }

  void _dockToNearestEdge() {
    final size = MediaQuery.of(context).size;
    final isCloserToLeft = _x < size.width / 2;
    
    final targetX = isCloserToLeft ? 0.0 : size.width - 32.0; // 32 is docked size
    final targetY = _y;

    _springAnimation = Tween<Offset>(
      begin: Offset(_x, _y),
      end: Offset(targetX, targetY),
    ).animate(CurvedAnimation(parent: _springController, curve: Curves.elasticOut));

    setState(() {
      _isDocked = true;
    });
    _springController.forward(from: 0);
  }

  void _restoreFromDock() {
    final size = MediaQuery.of(context).size;
    final isLeft = _x < size.width / 2;
    
    final targetX = isLeft ? 16.0 : size.width - 72.0; // Restored X padding
    final targetY = _y;

    _springAnimation = Tween<Offset>(
      begin: Offset(_x, _y),
      end: Offset(targetX, targetY),
    ).animate(CurvedAnimation(parent: _springController, curve: Curves.easeOutCubic));

    setState(() {
      _isDocked = false;
    });
    _springController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox();

    final isGlassEnabled = context.watch<ThemeProvider>().isGlassmorphismEnabled;

    Widget fabContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_isDocked) {
            HapticFeedback.lightImpact();
            _restoreFromDock();
          } else {
            widget.onPressed();
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isDocked
              ? BackdropFilter(
                  key: const ValueKey('docked'),
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                )
              : SingleChildScrollView(
                  key: const ValueKey('expanded'),
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.label != null && !_isDragging && !_springController.isAnimating) ...[
                        const SizedBox(width: 16),
                        Icon(widget.icon, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          widget.label!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                      ] else ...[
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: Center(child: Icon(widget.icon, color: Colors.white)),
                        ),
                      ]
                    ],
                  ),
                ),
        ),
      ),
    );

    // Calculate jelly stretch transformation
    final double scaleX = 1.0 + (_dragDelta.dx.abs() * 0.015).clamp(0.0, 0.2) - (_dragDelta.dy.abs() * 0.005).clamp(0.0, 0.1);
    final double scaleY = 1.0 + (_dragDelta.dy.abs() * 0.015).clamp(0.0, 0.2) - (_dragDelta.dx.abs() * 0.005).clamp(0.0, 0.1);

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onLongPress: () {
          if (!_isDocked) {
            HapticFeedback.mediumImpact();
            _dockToNearestEdge();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100), // Fast response for stretch transform
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(scaleX, scaleY),
          transformAlignment: Alignment.center,
          width: _isDocked ? 32 : (widget.label != null && !_isDragging && !_springController.isAnimating ? null : 56),
          height: _isDocked ? 32 : 56,
          decoration: BoxDecoration(
            color: isGlassEnabled 
                ? AppColors.primary.withValues(alpha: _isDocked ? 0.3 : 0.6)
                : (_isDocked ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary),
            borderRadius: BorderRadius.circular(_isDocked ? 12 : (_isDragging ? 32 : 28)), // Slightly rounder when dragging
            border: isGlassEnabled 
                ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5)
                : null,
            boxShadow: _isDragging || _isDocked
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isDocked ? 12 : (_isDragging ? 32 : 28)),
            child: isGlassEnabled
                ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: fabContent,
                  )
                : fabContent,
          ),
        ),
      ),
    );
  }
}

