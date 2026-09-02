import 'package:flutter/material.dart';
import 'banataq_mark.dart';

/// Looped B construction — same geometric B as app icon / splash.
/// Breathing glow, not pen nib.
class WelcomeAnimation extends StatefulWidget {
  const WelcomeAnimation({super.key, this.size = 170});
  final double size;
  @override
  State<WelcomeAnimation> createState() => _WelcomeAnimationState();
}

class _WelcomeAnimationState extends State<WelcomeAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(animation: _c, builder: (_, __) {
      final p = _c.value;
      final draw = (p / 0.62).clamp(0.0, 1.0).toDouble();
      final opacity = p < 0.78 ? 1.0 : (1 - (p - 0.78) / 0.22).clamp(0.0, 1.0).toDouble();
      return Opacity(opacity: opacity, child: BanataqMark(size: widget.size, progress: reduce ? 1 : draw, glow: reduce ? 0 : (p < 0.62 ? 0 : 0.4), reducedMotion: reduce));
    });
  }
}
