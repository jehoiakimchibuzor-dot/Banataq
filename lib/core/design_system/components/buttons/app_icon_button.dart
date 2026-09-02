import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

enum AppIconButtonVariant { standard, filled, tonal }

/// Themed icon button with consistent touch targets and tooltips.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.tooltip,
    this.color,
    this.size,
    this.isSelected = false,
    this.constraints,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final String? tooltip;
  final Color? color;
  final double? size;
  final bool isSelected;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? (isSelected ? scheme.primary : scheme.onSurfaceVariant);

    final style = switch (variant) {
      AppIconButtonVariant.standard => IconButton.styleFrom(
          foregroundColor: effectiveColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.appRadius.sm)),
        ),
      AppIconButtonVariant.filled => IconButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.appRadius.sm)),
        ),
      AppIconButtonVariant.tonal => IconButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.appRadius.sm)),
        ),
    };

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: size),
      style: style,
      constraints: constraints,
    );
  }
}
