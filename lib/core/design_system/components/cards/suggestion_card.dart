import 'package:flutter/material.dart';
import '../app_card.dart';

/// A proactive AI suggestion — an action proposed before being asked.
/// Always carries an apply path and a silent dismissal.
class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.title,
    required this.onApply,
    required this.onDismiss,
    this.description,
    this.icon = Icons.rocket_launch_outlined,
    this.applyLabel = 'Do this',
    this.suppressLabel = 'Not now',
    this.onSuppress,
  });

  final String title;
  final String? description;
  final IconData icon;
  final String applyLabel;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  final String suppressLabel;
  final VoidCallback? onSuppress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, size: 38, iconSize: 19),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.tonal(
                      onPressed: onApply,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: Text(applyLabel),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onSuppress ?? onDismiss,
                      child: Text(suppressLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
