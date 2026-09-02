import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

/// Branded floating action button. Regular circular by default, extended with
/// a label when [label] is provided.
class AppFAB extends StatelessWidget {
  const AppFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.appRadius.md));
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: tooltip,
        shape: shape,
        icon: Icon(icon),
        label: Text(label!),
      );
    }
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      shape: shape,
      child: Icon(icon),
    );
  }
}
