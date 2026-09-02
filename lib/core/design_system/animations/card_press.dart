import 'package:flutter/material.dart';

/// Wraps a child with a tactile press-scale feedback. Use on cards and tiles
/// that navigate or act — it is the standard "card press" micro-interaction.
class CardPress extends StatefulWidget {
  const CardPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.98,
    this.duration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration? duration;

  @override
  State<CardPress> createState() => _CardPressState();
}

class _CardPressState extends State<CardPress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 120),
      reverseDuration: widget.duration ?? const Duration(milliseconds: 120),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 1.0, end: widget.pressedScale));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) => _controller.forward();

  void _handleTapUp(TapUpDetails details) => _controller.reverse();

  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
