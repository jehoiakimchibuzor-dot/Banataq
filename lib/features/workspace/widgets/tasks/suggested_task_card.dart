import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_task.dart';

/// An AI-proposed task with Accept / Dismiss actions.
class SuggestedTaskCard extends StatelessWidget {
  const SuggestedTaskCard({
    super.key,
    required this.task,
    required this.onAccept,
    required this.onDismiss,
  });

  final WorkspaceTask task;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      outlined: true,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconTile(
            icon: Icons.auto_awesome_rounded,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AiBadge(label: 'Suggested', compact: true),
                    const SizedBox(width: 6),
                    if (task.priority == TaskPriority.high)
                      AppBadge(
                        label: task.priority.label,
                        tone: AppBadgeTone.warning,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.title,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppButton(
                      label: 'Accept',
                      icon: Icons.add_rounded,
                      onPressed: onAccept,
                      height: 36,
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Dismiss',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
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
