import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_task.dart';
import '../../widgets/tasks/suggested_task_card.dart';
import '../../widgets/tasks/task_tile.dart';
import '../workspace_controller.dart';

enum _TaskFilter { all, today, upcoming, completed }

/// Tasks tab â€” today's tasks, upcoming, completed and AI-suggested work.
class TasksTab extends StatefulWidget {
  const TasksTab({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final loading = controller.isLoading;
        final tasks = loading ? const <WorkspaceTask>[] : controller.tasks;
        final base = _query.isEmpty ? tasks : _searchTasks(tasks);
        final sections = _sectionsFor(base);

        final slivers = <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading
                        ? 'Loading tasks...'
                        : '${controller.tasks.length} tasks · ${controller.tasks.where((t) => !t.done).length} open',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  SizedBox(height: spacing.md),
                  _StatsRow(tasks: tasks),
                  SizedBox(height: spacing.md),
                  _ProgressCard(tasks: tasks),
                  SizedBox(height: spacing.md),
                  AppSearchField(
                    controller: _search,
                    hint: 'Search tasks...',
                    onChanged: (value) => setState(() {
                      _query = value.trim().toLowerCase();
                    }),
                  ),
                  SizedBox(height: spacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _TaskFilter.values) ...[
                          AppFilterChip(
                            label: switch (f) {
                              _TaskFilter.all => 'All',
                              _TaskFilter.today => 'Today',
                              _TaskFilter.upcoming => 'Upcoming',
                              _TaskFilter.completed => 'Completed',
                            },
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                          if (f != _TaskFilter.values.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (loading)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              sliver: SliverToBoxAdapter(child: SkeletonList(count: 6)),
            )
          else if (base.isEmpty && controller.suggestedTasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    size: 42,
                    color: scheme.primary,
                  ),
                ),
                title: _query.isEmpty ? 'No tasks yet' : 'No tasks found',
                description: _query.isEmpty
                    ? 'Tasks you add or that Banataq suggests will show up here.'
                    : 'Try a different keyword or filter.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xxl),
              sliver: SliverList.list(children: _buildSections(sections)),
            ),
        ];

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            key: const PageStorageKey('workspace-tasks'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          ),
        );
      },
    );
  }

  List<Widget> _buildSections(_TaskSections sections) {
    final spacing = context.appSpacing;
    final items = <Widget>[];

    if (_filter != _TaskFilter.completed) {
      if (widget.controller.suggestedTasks.isNotEmpty && _query.isEmpty) {
        items.add(const AppSectionHeader(
          title: 'Suggested for you',
          subtitle: 'Generated by Banataq',
        ));
        for (final t in widget.controller.suggestedTasks) {
          items.add(
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: SuggestedTaskCard(
                task: t,
                onAccept: () => widget.controller.acceptSuggestion(t),
                onDismiss: () => widget.controller.dismissSuggestion(t),
              ),
            ),
          );
        }
      } else if (widget.controller.suggestedTasks.isEmpty &&
          _filter == _TaskFilter.all &&
          _query.isEmpty) {
        items.add(Padding(
          padding: EdgeInsets.only(bottom: spacing.sm),
          child: AppCard(
            outlined: true,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AiBadge(label: 'AI suggestions'),
                      SizedBox(height: 6),
                      Text('Let Banataq suggest next steps for this week.'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: 'Suggest',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: widget.controller.generateSuggestions,
                  height: 40,
                ),
              ],
            ),
          ),
        ));
      }
    }

    void addSection(String title, String? subtitle, List<WorkspaceTask> list) {
      if (list.isEmpty) return;
      items.add(AppSectionHeader(title: title, subtitle: subtitle));
      items.addAll([
        for (final t in list)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: TaskTile(
              task: t,
              onToggle: (done) => widget.controller.toggleTask(t, done),
              onSubtaskToggle:
                  (index, done) => widget.controller.toggleSubtask(t, index, done),
              onDelete: () => _confirmDelete(t),
            ),
          ),
      ]);
    }

    addSection(
      'Overdue',
      sections.overdue.isNotEmpty
          ? '${sections.overdue.length} past due'
          : null,
      sections.overdue,
    );
    addSection(
      'Today',
      sections.today.isNotEmpty ? '${sections.today.length} for today' : null,
      sections.today,
    );
    addSection('Upcoming', null, sections.upcoming);
    addSection('Completed', null, sections.completed);

    return items;
  }

  _TaskSections _sectionsFor(List<WorkspaceTask> tasks) {
    List<WorkspaceTask> open = tasks.where((t) => !t.done).toList();
    List<WorkspaceTask> done = tasks.where((t) => t.done).toList();

    List<WorkspaceTask> by(TaskDueGroup group) =>
        open.where((t) => t.dueGroup == group).toList();

    switch (_filter) {
      case _TaskFilter.all:
        return _TaskSections(
          overdue: by(TaskDueGroup.overdue),
          today: by(TaskDueGroup.today),
          upcoming: [...by(TaskDueGroup.upcoming), ...by(TaskDueGroup.none)],
          completed: done,
        );
      case _TaskFilter.today:
        return _TaskSections(
          overdue: by(TaskDueGroup.overdue),
          today: by(TaskDueGroup.today),
          upcoming: const [],
          completed: const [],
        );
      case _TaskFilter.upcoming:
        return _TaskSections(
          overdue: const [],
          today: const [],
          upcoming: [...by(TaskDueGroup.upcoming), ...by(TaskDueGroup.none)],
          completed: const [],
        );
      case _TaskFilter.completed:
        return _TaskSections(
          overdue: const [],
          today: const [],
          upcoming: const [],
          completed: done,
        );
    }
  }

  List<WorkspaceTask> _searchTasks(List<WorkspaceTask> tasks) {
    return tasks
        .where(
          (t) => t.title.toLowerCase().contains(_query),
        )
        .toList();
  }

  Future<void> _confirmDelete(WorkspaceTask task) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Delete task?',
      message: '"${task.title}" will be removed from the task list.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true && mounted) {
      widget.controller.deleteTask(task);
    }
  }
}

class _TaskSections {
  const _TaskSections({
    required this.overdue,
    required this.today,
    required this.upcoming,
    required this.completed,
  });

  final List<WorkspaceTask> overdue;
  final List<WorkspaceTask> today;
  final List<WorkspaceTask> upcoming;
  final List<WorkspaceTask> completed;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.tasks});

  final List<WorkspaceTask> tasks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final done = tasks.where((t) => t.done).length;
    final open = tasks.where((t) => !t.done).toList();
    final todayCount = open.where((t) {
      final due = t.dueDate;
      if (due == null) return false;
      final day = DateTime(due.year, due.month, due.day);
      return !day.isBefore(todayStart);
    }).length;
    final overdueCount = open.where((t) => t.isOverdue).length;

    final cards = [
      StatisticsCard(
        value: '$done',
        label: 'Done',
        icon: Icons.check_circle_outline_rounded,
        tone: StatusTone.success,
      ),
      StatisticsCard(
        value: '$todayCount',
        label: 'Due soon',
        icon: Icons.event_rounded,
        tone: StatusTone.info,
      ),
      StatisticsCard(
        value: '$overdueCount',
        label: 'Overdue',
        icon: Icons.warning_amber_rounded,
        tone: StatusTone.danger,
      ),
      StatisticsCard(
        value: '${open.length}',
        label: 'In progress',
        icon: Icons.bolt_rounded,
        tone: StatusTone.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 10.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Column(
          children: [
            Row(
              children: [
                SizedBox(width: width, child: cards[0]),
                SizedBox(width: gap),
                SizedBox(width: width, child: cards[1]),
              ],
            ),
            SizedBox(height: gap),
            Row(
              children: [
                SizedBox(width: width, child: cards[2]),
                SizedBox(width: gap),
                SizedBox(width: width, child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.tasks});

  final List<WorkspaceTask> tasks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = tasks.where((t) => t.done).length;
    final total = tasks.length;
    final value = total == 0 ? 0.0 : done / total;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Task progress',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$done of $total done',
                style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppProgress.linear(value: value, minHeight: 6),
        ],
      ),
    );
  }
}
