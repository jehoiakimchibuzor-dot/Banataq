import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../domain/models/workspace_search.dart';
import '../domain/models/workspace_session.dart';
import '../domain/models/workspace_task.dart';
import '../domain/models/workspace_timeline.dart';
import '../widgets/files/file_detail_sheet.dart';
import 'workspace_controller.dart';

/// Workspace-wide search across sessions, tasks, files, memory and timeline.
///
/// Live results are driven by [WorkspaceController.search]; the controller
/// owns the debounce so the screen stays a thin view.
class WorkspaceSearchScreen extends StatefulWidget {
  const WorkspaceSearchScreen({super.key, required this.controller});

  final WorkspaceController controller;

  static const routeName = '/workspace-search';

  @override
  State<WorkspaceSearchScreen> createState() => _WorkspaceSearchScreenState();
}

class _WorkspaceSearchScreenState extends State<WorkspaceSearchScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    widget.controller.clearSearch();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value.trim());
    widget.controller.search(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AppSearchField(
            controller: _search,
            hint: 'Search this workspace...',
            autofocus: true,
            onChanged: _onChanged,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;
          final searching = controller.isSearching;
          final results = controller.searchResults;

          if (_query.isEmpty) {
            return _PromptState();
          }
          if (searching) {
            return const Center(child: CircularProgressIndicator());
          }
          if (results.isEmpty) {
            return AppEmptyState(
              icon: Icon(
                Icons.search_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: 'No results for "$_query"',
              description: 'Try a different keyword or check the spelling.',
            );
          }
          return _Results(
            controller: controller,
            results: results,
          );
        },
      ),
    );
  }
}

class _PromptState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: spacing.md),
            Text(
              'Search everything in this workspace',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            SizedBox(height: spacing.xs),
            Text(
              'Chats, tasks, files, memory and activity.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.controller, required this.results});

  final WorkspaceController controller;
  final WorkspaceSearchResults results;

  @override
  Widget build(BuildContext context) {
    final sections = <(String, List<Widget>)>[];

    if (results.sessions.isNotEmpty) {
      sections.add((
        'Chats',
        [
          for (final s in results.sessions)
            _ResultRow(
              icon: Icons.forum_outlined,
              title: s.title,
              subtitle: s.purpose ?? s.summary,
              trailing: Text(
                s.status.label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              onTap: () => controller.onOpenSession?.call(s),
            ),
        ],
      ));
    }
    if (results.tasks.isNotEmpty) {
      sections.add((
        'Tasks',
        [
          for (final t in results.tasks)
            _ResultRow(
              icon: t.done ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
              title: t.title,
              subtitle: t.contextLabel ?? t.dueGroupLabel,
              onTap: () => controller.toggleTask(t, !t.done),
            ),
        ],
      ));
    }
    if (results.files.isNotEmpty) {
      sections.add((
        'Files',
        [
          for (final f in results.files)
            _ResultRow(
              icon: f.type.icon,
              title: f.name,
              subtitle: f.type.label,
              onTap: () => showFileDetailSheet(context, controller, f),
            ),
        ],
      ));
    }
    if (results.memories.isNotEmpty) {
      sections.add((
        'Memory',
        [
          for (final m in results.memories)
            _ResultRow(
              icon: Icons.lightbulb_outline_rounded,
              title: m.title,
              subtitle: m.content,
              onTap: () => controller.toggleMemoryPinned(m),
            ),
        ],
      ));
    }
    if (results.timeline.isNotEmpty) {
      sections.add((
        'Timeline',
        [
          for (final e in results.timeline)
            _ResultRow(
              icon: e.type.icon,
              title: e.title,
              subtitle: e.description,
              onTap: e.type == TimelineEventType.session
                  ? () => _openSession(controller, e)
                  : null,
            ),
        ],
      ));
    }

    return ListView(
      key: const PageStorageKey('workspace-search-results'),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        for (final (title, rows) in sections) ...[
          AppSectionHeader(
            title: title,
            subtitle: '${rows.length} ${rows.length == 1 ? 'result' : 'results'}',
          ),
          ...rows,
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _openSession(WorkspaceController controller, TimelineEvent event) {
    final session =
        controller.sessions.where((s) => s.id == event.refId).toList();
    if (session.isNotEmpty) controller.onOpenSession?.call(session.first);
  }
}

extension on WorkspaceTask {
  String get dueGroupLabel => switch (dueGroup) {
        TaskDueGroup.overdue => 'Overdue',
        TaskDueGroup.today => 'Due today',
        TaskDueGroup.upcoming => 'Upcoming',
        TaskDueGroup.none => contextLabel ?? 'No due date',
      };
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(context.appRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AppIconTile(icon: icon, size: 36, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
