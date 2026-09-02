import 'package:flutter/material.dart';

/// Custom divider styles for the design system.
///
/// Prefer this over a raw [Divider] so thickness and color stay theme-driven.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.hairline = false,
    this.strong = false,
    this.indent = 0,
    this.endIndent = 0,
    this.color,
    this.height,
  })  : assert(!(hairline && strong), 'Cannot be both hairline and strong');

  /// Extra-faint divider.
  final bool hairline;

  /// Emphasized divider.
  final bool strong;

  final double indent;
  final double endIndent;
  final Color? color;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = color ?? scheme.outlineVariant;

    return Divider(
      height: height ?? 1,
      thickness: strong ? 1.5 : 1,
      indent: indent,
      endIndent: endIndent,
      color: strong
          ? base
          : hairline
              ? base.withValues(alpha: 0.35)
              : base.withValues(alpha: 0.7),
    );
  }
}

/// Vertical divider for row-based layouts.
class AppVerticalDivider extends StatelessWidget {
  const AppVerticalDivider({
    super.key,
    this.height = double.infinity,
    this.thickness = 1,
    this.color,
  });

  final double height;
  final double thickness;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return VerticalDivider(
      width: thickness * 2 + 8,
      thickness: thickness,
      color: color ?? scheme.outlineVariant.withValues(alpha: 0.7),
      indent: 0,
      endIndent: 0,
    );
  }
}
