import 'package:flutter/material.dart';
import '../theme/app_theme_context.dart';

/// Base surface for the whole card system.
///
/// Specialized cards (workspace, insight, file, …) compose this primitive so
/// radius, elevation, ripple and border stay consistent everywhere.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderRadius,
    this.outlined = false,
    this.elevated = false,
    this.shadows,
    this.border,
  });

  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;
  final bool outlined;
  final bool elevated;
  final List<BoxShadow>? shadows;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(context.appRadius.lg);
    final effectiveShadows = shadows ??
        (elevated ? context.appShadows.sm : null);

    final decoration = BoxDecoration(
      color: color ?? scheme.surfaceContainerLow,
      borderRadius: radius,
      border: border ??
          (outlined ? Border.all(color: scheme.outlineVariant) : null),
      boxShadow: effectiveShadows,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null && onLongPress == null) {
      return Container(
        margin: margin,
        decoration: decoration,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: content,
        ),
      ),
    );
  }
}

/// Renders an icon inside a rounded, softly tinted square — the shared
/// leading visual for cards and list rows.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize,
    this.color,
    this.borderRadius,
    this.emoji,
  });

  final IconData? icon;
  final String? emoji;
  final double size;
  final double? iconSize;
  final Color? color;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = color ?? scheme.primaryContainer;
    final fg = ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
        ? scheme.onPrimaryContainer
        : scheme.primary;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: borderRadius ?? BorderRadius.circular(context.appRadius.sm),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: iconSize ?? size * 0.45))
          : Icon(icon, size: iconSize ?? size * 0.5, color: fg),
    );
  }
}
