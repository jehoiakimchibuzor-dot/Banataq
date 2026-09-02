import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

/// Base chip with theme-driven styling. Specialized chips extend this.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.avatar,
    this.selected = false,
    this.onPressed,
    this.onSelected,
    this.onDeleted,
    this.selectedColor,
    this.tooltip,
  });

  final String label;
  final IconData? icon;
  final Widget? avatar;
  final bool selected;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final Color? selectedColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final chip = RawChip(
      label: Text(label),
      avatar: avatar,
      avatarBoxConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      showCheckmark: false,
      selected: selected,
      onSelected: onSelected ?? (onPressed != null ? (_) => onPressed!() : null),
      deleteIcon: onDeleted != null
          ? Icon(Icons.close_rounded, size: 16, color: scheme.onSurfaceVariant)
          : null,
      onDeleted: onDeleted,
      selectedColor: selectedColor ?? scheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? (selectedColor ?? scheme.primary) : scheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.appRadius.pill)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      tooltip: tooltip,
    );

    if (icon == null) return chip;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 5),
        chip,
      ],
    );
  }
}

/// Selectable filter chip for list filtering.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: count != null ? Text('$label $count') : Text(label),
      avatar: icon != null
          ? Icon(icon, size: 15, color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)
          : null,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.appRadius.pill)),
      labelStyle: TextStyle(
        color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    );
  }
}

/// A memory/tag chip — a fact stored in project memory. Dismissible.
class AppMemoryChip extends StatelessWidget {
  const AppMemoryChip({
    super.key,
    required this.label,
    this.onDeleted,
    this.onTap,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final String label;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppChip(
      label: label,
      icon: icon,
      selected: true,
      onPressed: onTap,
      onDeleted: onDeleted,
      tooltip: 'Memory: $label',
    );
  }
}

/// A static category/context label (e.g. "From Aug 1 session").
class AppCategoryChip extends StatelessWidget {
  const AppCategoryChip({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppChip(label: label, icon: icon);
  }
}


