import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_task.dart';

/// Tasks section of the Overview tab. Rows are tappable; tapping toggles the
/// task's checked state (local-only in this sprint).
class TasksPreview extends StatefulWidget {
  const TasksPreview({
    super.key,
    required this.tasks,
    this.onTaskToggle,
    this.onSeeAll,
  });

  final List<WorkspaceTask> tasks;
  final void Function(WorkspaceTask task, bool done)? onTaskToggle;
  final VoidCallback? onSeeAll;

  @override
  State<TasksPreview> createState() => _TasksPreviewState();
}

class _TasksPreviewState extends State<TasksPreview> {
  late final Set<String> _done = {
    for (final t in widget.tasks)
      if (t.done) t.id,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppSectionList(
      title: 'Tasks',
      actionLabel: 'See all',
      onAction: widget.onSeeAll,
      separated: false,
      children: [
        for (var i = 0; i < widget.tasks.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == widget.tasks.length - 1 ? 0 : 6),
            child: _TaskRow(
              task: widget.tasks[i],
              done: _done.contains(widget.tasks[i].id),
              onToggle: (value) {
                setState(() {
                  if (value) {
                    _done.add(widget.tasks[i].id);
                  } else {
                    _done.remove(widget.tasks[i].id);
                  }
                });
                widget.onTaskToggle?.call(widget.tasks[i], value);
              },
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppProgress.linear(
                value: _done.length / widget.tasks.length,
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${_done.length}/${widget.tasks.length}',
              style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.done,
    required this.onToggle,
  });

  final WorkspaceTask task;
  final bool done;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onToggle(!done),
      borderRadius: BorderRadius.circular(context.appRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            AppCheckbox(value: done, onChanged: onToggle),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                  if (task.dueLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.dueLabel!,
                      style: textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            if (task.priority != TaskPriority.medium) ...[
              const SizedBox(width: 8),
              AppBadge(
                label: task.priority.label,
                tone: switch (task.priority) {
                  TaskPriority.high => AppBadgeTone.danger,
                  TaskPriority.medium => AppBadgeTone.warning,
                  TaskPriority.low => AppBadgeTone.neutral,
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
