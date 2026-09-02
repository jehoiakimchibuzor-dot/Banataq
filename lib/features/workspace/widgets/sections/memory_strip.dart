import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_memory.dart';

/// Rolling "memory" strip that the AI writes to after every session.
class MemoryStrip extends StatelessWidget {
  const MemoryStrip({
    super.key,
    required this.entries,
    this.onOpenAll,
  });

  final List<WorkspaceMemory> entries;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return AppSectionList(
      title: 'Memory',
      actionLabel: 'Open memory',
      onAction: onOpenAll,
      separated: false,
      children: [
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(context.appRadius.lg),
          ),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sm,
                    vertical: spacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _iconFor(entries[i].category),
                        size: 18,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entries[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entries[i].content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            if (entries[i].source != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                entries[i].source!,
                                style: textTheme.labelSmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (entries[i].pinned) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: scheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _iconFor(MemoryCategory category) => switch (category) {
        MemoryCategory.preferences => Icons.tune_rounded,
        MemoryCategory.contacts => Icons.person_outline_rounded,
        MemoryCategory.goals => Icons.flag_outlined,
        MemoryCategory.decisions => Icons.rule_rounded,
        MemoryCategory.context => Icons.info_outline_rounded,
        MemoryCategory.rules => Icons.policy_outlined,
      };
}
