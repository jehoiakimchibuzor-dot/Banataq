import 'package:flutter/material.dart';
import '../app_card.dart';

/// Represents a project / workspace on the dashboard.
///
/// Carries identity, an AI-derived progress and a one-line context summary.
class WorkspaceCard extends StatelessWidget {
  const WorkspaceCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.emoji,
    this.icon,
    this.progress,
    this.progressLabel,
    this.summary,
    this.lastActivity,
    this.pinned = false,
    this.selected = false,
    this.onLongPress,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? emoji;
  final IconData? icon;
  final double? progress;
  final String? progressLabel;
  final String? summary;
  final String? lastActivity;
  final bool pinned;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      color: selected ? scheme.primaryContainer : null,
      border: selected
          ? Border.all(color: scheme.primary)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(icon: icon, emoji: emoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pinned) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.push_pin_rounded,
                              size: 14, color: scheme.primary),
                        ],
                      ],
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 10),
            Text(
              summary!,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      minHeight: 5,
                    ),
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    progressLabel!,
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
          if (lastActivity != null) ...[
            const SizedBox(height: 10),
            Text(
              lastActivity!,
              style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
