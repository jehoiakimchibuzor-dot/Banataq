import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../../theme/app_theme_extensions.dart';
import '../app_card.dart';

/// A passive, dismissible AI insight card. Kept to one sentence plus an
/// optional next step so insights never become noise.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.onDismiss,
    this.description,
    this.icon = Icons.auto_awesome_rounded,
    this.actionLabel,
    this.onAction,
    this.tone = StatusTone.info,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantics = context.appSemantics;
    final accent = semantics.foregroundFor(tone);
    final container = semantics.containerFor(tone);

    return AppCard(
      padding: const EdgeInsets.all(14),
      color: scheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: icon,
            size: 36,
            iconSize: 18,
            color: container,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(color: accent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: textTheme.labelMedium?.copyWith(color: accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 16),
            iconSize: 16,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
