import 'package:flutter/animation.dart';

/// Standard easing curves for the design system.
abstract final class AppCurves {
  /// Default entrance curve — fast start, calm settle.
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Default for bidirectional/state transitions.
  static const Curve easeInOutCubic = Curves.easeInOutCubic;

  /// Playful "snap" used on selection highlights and small scale pops.
  static const Curve easeOutBack = Curves.easeOutBack;

  /// Linear, for infinite/looping animations.
  static const Curve linear = Curves.linear;
}
