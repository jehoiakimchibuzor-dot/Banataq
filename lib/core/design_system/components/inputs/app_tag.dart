import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../../theme/app_theme_extensions.dart';

/// A small tag/role label (e.g. persona, category). Static, read-only.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusTone.info,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = context.appSemantics;
    final accent = semantics.foregroundFor(tone);
    final container = semantics.containerFor(tone).withValues(alpha: 0.85);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: container,
          borderRadius: BorderRadius.circular(context.appRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
