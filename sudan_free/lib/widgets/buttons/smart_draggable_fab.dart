import 'dart:ui';
import 'package:flutter/material.dart';
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

  late AnimationController _springController;
  late Animation<Offset> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _springController.addListener(() {
      if (_springController.isAnimating) {
        setState(() {
          _x = _springAnimation.value.dx;
          _y = _springAnimation.value.dy;
        });
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
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDocked) return;
    setState(() {
      _x += details.delta.dx;
      _y += details.delta.dy;

      // Keep within screen bounds
      final size = MediaQuery.of(context).size;
      _x = _x.clamp(0.0, size.width - 56.0);
      _y = _y.clamp(MediaQuery.of(context).padding.top, size.height - 56.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDocked) return;
    setState(() {
      _isDragging = false;
    });
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

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onLongPress: () {
          if (!_isDocked) {
            _dockToNearestEdge();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: _isDocked ? 32 : (widget.label != null && !_isDragging ? null : 56),
          height: _isDocked ? 32 : 56,
          decoration: BoxDecoration(
            color: _isDocked ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary,
            borderRadius: BorderRadius.circular(_isDocked ? 12 : 28),
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
            borderRadius: BorderRadius.circular(_isDocked ? 12 : 28),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_isDocked) {
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
                              if (widget.label != null && !_isDragging) ...[
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
            ),
          ),
        ),
      ),
    );
  }
}
