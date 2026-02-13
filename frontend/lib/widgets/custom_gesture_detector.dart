import 'package:flutter/material.dart';

class CustomGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration animationDuration;
  final double scale;
  final bool enableScale;

  const CustomGestureDetector({
    Key? key,
    required this.child,
    required this.onTap,
    this.animationDuration = const Duration(milliseconds: 100),
    this.scale = 0.95,
    this.enableScale = true,
  }) : super(key: key);

  @override
  State<CustomGestureDetector> createState() => _CustomGestureDetectorState();
}

class _CustomGestureDetectorState extends State<CustomGestureDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enableScale) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enableScale) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enableScale) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _animation, child: widget.child),
    );
  }
}
