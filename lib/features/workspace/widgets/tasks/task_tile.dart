import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_task.dart';

/// A single task row: animated checkbox, priority, due date, context and
/// optional subtasks. Used by the Tasks tab.
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onSubtaskToggle,
    this.onDelete,
    this.onTap,
    this.showDue = true,
  });

  final WorkspaceTask task;
  final ValueChanged<bool> onToggle;
  final void Function(int index, bool done)? onSubtaskToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showDue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    final titleStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: task.done ? scheme.onSurfaceVariant : scheme.onSurface,
      decoration: task.done ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: scheme.onSurfaceVariant,
    );

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppCheckbox(
                  value: task.done,
                  onChanged: onToggle,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: titleStyle!,
                      child: Text(task.title),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _PriorityChip(priority: task.priority),
                        if (showDue) _DueLabel(task: task),
                        if (task.contextLabel != null)
                          AppTag(
                            label: task.contextLabel!,
                            tone: StatusTone.info,
                          ),
                        if (task.source == TaskSource.ai)
                          const AiBadge(label: 'AI suggested', compact: true),
                        if (task.hasSubtasks)
                          _MetaText(
                            '${task.doneSubtasks}/${task.subtasks.length}',
                            icon: Icons.checklist_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null) _DeleteMenu(onDelete: onDelete!),
            ],
          ),
          if (task.hasSubtasks) ...[
            const SizedBox(height: 8),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: Column(
                children: [
                  for (var i = 0; i < task.subtasks.length; i++)
                    _SubtaskRow(
                      title: task.subtasks[i].title,
                      done: task.subtasks[i].done,
                      onChanged:
                          onSubtaskToggle == null
                              ? null
                              : (v) => onSubtaskToggle!(i, v),
                    ),
                ],
              ),
            ),
            SizedBox(height: spacing.xs),
          ],
        ],
      ),
    );
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.title,
    required this.done,
    required this.onChanged,
  });

  final String title;
  final bool done;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppCheckbox(value: done, onChanged: onChanged, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: scheme.onSurfaceVariant,
                  ),
              child: Text(title),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final tone = switch (priority) {
      TaskPriority.high => StatusTone.danger,
      TaskPriority.medium => StatusTone.warning,
      TaskPriority.low => StatusTone.info,
    };
    return AppTag(
      label: priority.label,
      tone: tone,
      icon: switch (priority) {
        TaskPriority.high => Icons.arrow_upward_rounded,
        TaskPriority.medium => Icons.remove_rounded,
        TaskPriority.low => Icons.arrow_downward_rounded,
      },
    );
  }
}

class _DueLabel extends StatelessWidget {
  const _DueLabel({required this.task});

  final WorkspaceTask task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = task.isOverdue;
    final label = task.effectiveDueLabel;
    final color = overdue
        ? context.appSemantics.danger
        : scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          overdue ? Icons.warning_amber_rounded : Icons.event_rounded,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.label, {required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _DeleteMenu extends StatelessWidget {
  const _DeleteMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Task actions',
      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appRadius.sm),
      ),
      onSelected: (_) => onDelete(),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: scheme.error),
              const SizedBox(width: 10),
              Text(
                'Delete',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
