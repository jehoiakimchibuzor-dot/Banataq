import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

/// Themed checkbox with consistent shape, ripple and animation.
///
/// Tapping the box toggles the value; the whole hit area is a generous
/// [InkWell] so rows don't need to fiddle with tap targets.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    this.value = false,
    this.onChanged,
    this.size = 22,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = context.appRadius;

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(radius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(radius.sm),
          border: Border.all(
            color: value ? scheme.primary : scheme.outlineVariant,
            width: 1.6,
          ),
        ),
        child: value
            ? Icon(Icons.check_rounded, size: size * 0.7, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}
