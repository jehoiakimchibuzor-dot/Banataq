import 'package:flutter/material.dart';

/// Slides a child in from an offset on mount. Defaults to a gentle rise,
/// ideal for list rows and sheet contents.
class SlideIn extends StatefulWidget {
  const SlideIn({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.offset = const Offset(0, 0.08),
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration? duration;
  final Curve? curve;
  final Offset offset;
  final Duration delay;

  @override
  State<SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _position;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(milliseconds: 350),
    );
    final curve = widget.curve ?? Curves.easeOutCubic;
    _position = CurvedAnimation(parent: _controller, curve: curve).drive(
      Tween(begin: widget.offset, end: Offset.zero),
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
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}
