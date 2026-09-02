import 'dart:async';
import 'package:flutter/material.dart';

/// Fades a child in on mount. Delays are used for stagger entrances.
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.delay = Duration.zero,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final Duration? duration;
  final Curve? curve;
  final Duration delay;
  final AlignmentGeometry alignment;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    final duration = widget.duration ?? const Duration(milliseconds: 250);
    _controller = AnimationController(vsync: this, duration: duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve ?? Curves.easeOutCubic);
    if (widget.delay > Duration.zero) {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Align(alignment: widget.alignment, child: widget.child),
    );
  }
}
