import 'package:flutter/material.dart';

/// Scales a child in on mount (with a subtle fade). Best for cards and
/// hero elements entering a screen.
class ScaleIn extends StatefulWidget {
  const ScaleIn({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.beginScale = 0.92,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration? duration;
  final Curve? curve;
  final double beginScale;
  final Duration delay;

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 300),
    );
    final curve = widget.curve ?? Curves.easeOutBack;
    _scale = CurvedAnimation(parent: _controller, curve: curve).drive(
      Tween(begin: widget.beginScale, end: 1.0),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut).drive(
      Tween(begin: 0.0, end: 1.0),
    );
    if (widget.delay > Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
