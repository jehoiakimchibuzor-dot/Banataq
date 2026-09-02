import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../../animations/card_press.dart';

/// Compact utility tile (camera, voice, upload, scan…). Four of these make a
/// quick-action row; never exceed that to avoid choice paralysis.
class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.accent,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? subtitle;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = context.appRadius;
    final accentColor = accent ?? scheme.primary;
    final accentContainer = accentColor.withValues(alpha: 0.16);

    return CardPress(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(radius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentContainer,
                borderRadius: BorderRadius.circular(radius.sm),
              ),
              child: Icon(icon, size: compact ? 18 : 20, color: accentColor),
            ),
            SizedBox(height: compact ? 8 : 10),
            Text(
              label,
              style: textTheme.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
