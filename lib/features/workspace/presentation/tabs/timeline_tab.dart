import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_timeline.dart';
import '../../widgets/common/workspace_filter_chips.dart';
import '../../widgets/timeline/timeline_tile.dart';
import '../workspace_controller.dart';

enum _TimelineFilter { all, sessions, tasks, files, memory }

/// Timeline tab — a chronological history of the workspace.
///
/// Entries come from the service (sessions started, tasks completed, files
/// added, memories saved). Supports type filtering and day grouping.
class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  _TimelineFilter _filter = _TimelineFilter.all;

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
        final all = controller.timeline;
        final visible = loading ? const <TimelineEvent>[] : _filtered(all);

        final slivers = <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timeline',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading
                        ? 'Loading timeline...'
                        : '${all.length} activities across the workspace',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  SizedBox(height: spacing.md),
                  WorkspaceFilterChips(
                    options: [
                      for (final f in _TimelineFilter.values)
                        FilterOption(
                          label: switch (f) {
                            _TimelineFilter.all => 'All',
                            _TimelineFilter.sessions => 'Chats',
                            _TimelineFilter.tasks => 'Tasks',
                            _TimelineFilter.files => 'Files',
                            _TimelineFilter.memory => 'Memory',
                          },
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
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
          else if (visible.isEmpty)
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
                    Icons.timeline_rounded,
                    size: 42,
                    color: scheme.primary,
                  ),
                ),
                title: 'Nothing here yet',
                description: _filter == _TimelineFilter.all
                    ? 'Activity will appear here as you work on this workspace.'
                    : 'No activity in this category yet.',
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xxl),
              sliver: SliverList.list(children: _buildSections(visible)),
            ),
        ];

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            key: const PageStorageKey('workspace-timeline'),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: slivers,
          ),
        );
      },
    );
  }

  List<TimelineEvent> _filtered(List<TimelineEvent> all) {
    final type = switch (_filter) {
      _TimelineFilter.all => null,
      _TimelineFilter.sessions => TimelineEventType.session,
      _TimelineFilter.tasks => null,
      _TimelineFilter.files => TimelineEventType.file,
      _TimelineFilter.memory => TimelineEventType.memory,
    };
    if (type != null) {
      return all.where((e) => e.type == type).toList();
    }
    if (_filter == _TimelineFilter.tasks) {
      return all
          .where((e) =>
              e.type == TimelineEventType.task ||
              e.type == TimelineEventType.milestone)
          .toList();
    }
    return all;
  }

  List<Widget> _buildSections(List<TimelineEvent> visible) {
    final groups = <_DayGroup, List<TimelineEvent>>{};
    for (final e in visible) {
      groups.putIfAbsent(_dayGroupFor(e.occurredAt), () => []).add(e);
    }
    final items = <Widget>[];
    var index = 0;
    for (final group in _dayGroupOrder) {
      final list = groups[group] ?? const <TimelineEvent>[];
      if (list.isEmpty) continue;
      items.add(AppSectionHeader(
        title: _dayGroupLabel(group),
        subtitle: '${list.length} ${list.length == 1 ? 'activity' : 'activities'}',
      ));
      for (final e in list) {
        items.add(
          TimelineTile(
            event: e,
            isFirst: index == 0,
            isLast: index == visible.length - 1,
            onTap: e.type == TimelineEventType.session
                ? () => _openSession(e)
                : null,
          ),
        );
        index++;
      }
    }
    return items;
  }

  void _openSession(TimelineEvent event) {
    final session = widget.controller.sessions
        .where((s) => s.id == event.refId)
        .toList();
    if (session.isNotEmpty) {
      widget.controller.onOpenSession?.call(session.first);
    }
  }

  _DayGroup _dayGroupFor(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return _DayGroup.today;
    if (diff == 1) return _DayGroup.yesterday;
    if (diff < 7) return _DayGroup.thisWeek;
    return _DayGroup.earlier;
  }
}

enum _DayGroup { today, yesterday, thisWeek, earlier }

const List<_DayGroup> _dayGroupOrder = [
  _DayGroup.today,
  _DayGroup.yesterday,
  _DayGroup.thisWeek,
  _DayGroup.earlier,
];

String _dayGroupLabel(_DayGroup group) => switch (group) {
      _DayGroup.today => 'Today',
      _DayGroup.yesterday => 'Yesterday',
      _DayGroup.thisWeek => 'This week',
      _DayGroup.earlier => 'Earlier',
    };
