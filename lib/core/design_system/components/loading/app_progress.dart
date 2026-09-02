import 'package:flutter/material.dart';

/// Progress indicators with theme-driven tracks and rounded ends.
abstract final class AppProgress {
  /// Thin rounded linear progress.
  static Widget linear({
    double? value,
    double minHeight = 6,
    double? width,
    Color? color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: width,
        height: minHeight,
        child: LinearProgressIndicator(
          value: value,
          minHeight: minHeight,
          color: color,
        ),
      ),
    );
  }

  /// Branded circular progress with an optional value label.
  static Widget circular(
    BuildContext context, {
    double? value,
    double size = 40,
    double strokeWidth = 3,
    String? label,
    Color? color,
  }) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
    if (label == null) return indicator;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          indicator,
          Text(
            label,
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
