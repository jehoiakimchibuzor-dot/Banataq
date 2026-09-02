import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_session.dart';
import '../../widgets/sessions/session_card.dart';
import '../workspace_controller.dart';

enum _SessionFilter { all, pinned, active, archived }

/// Sessions tab — every focused working session with Banataq.
///
/// Supports search, recency grouping, filter chips, pin/archive/delete and
/// starting a new session. Shows loading skeletons on first load and supports
/// pull-to-refresh.
class SessionsTab extends StatefulWidget {
  const SessionsTab({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  _SessionFilter _filter = _SessionFilter.all;

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
        final all = controller.sessions;
        final visible = loading ? const <WorkspaceSession>[] : _filtered(all);

        final active = visible.where((s) => s.status == SessionStatus.inProgress).toList();
        final rest = visible.where((s) => s.status != SessionStatus.inProgress).toList();
        final groups = <SessionGroup, List<WorkspaceSession>>{
          for (final s in rest) _groupFor(s.updatedAt): <WorkspaceSession>[],
        };
        for (final s in rest) {
          groups[_groupFor(s.updatedAt)]!.add(s);
        }

        final slivers = <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chats',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading
                        ? 'Loading chats...'
                        : '${all.length} chats · ${active.length} in progress',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  SizedBox(height: spacing.md),
                  AppSearchField(
                    controller: _search,
                    hint: 'Search chats...',
                    onChanged: (value) => setState(() {
                      _query = value.trim().toLowerCase();
                    }),
                  ),
                  SizedBox(height: spacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _SessionFilter.values) ...[
                          AppFilterChip(
                            label: switch (f) {
                              _SessionFilter.all => 'All',
                              _SessionFilter.pinned => 'Pinned',
                              _SessionFilter.active => 'Active',
                              _SessionFilter.archived => 'Archived',
                            },
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                          if (f != _SessionFilter.values.last)
                            const SizedBox(width: 8),
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
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptySessions(
                onStart: _startNewSession,
                isSearching: _query.isNotEmpty,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xxl),
              sliver: SliverList.list(children: _buildSections(active, groups)),
            ),
        ];

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refresh,
              child: CustomScrollView(
                key: const PageStorageKey('workspace-sessions'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
              ),
            ),
            Positioned(
              right: spacing.md,
              bottom: spacing.md,
              child: AppFAB(
                icon: Icons.add_rounded,
                label: 'New chat',
                onPressed: _startNewSession,
                tooltip: 'Start a new chat',
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSections(
    List<WorkspaceSession> active,
    Map<SessionGroup, List<WorkspaceSession>> groups,
  ) {
    final spacing = context.appSpacing;
    final items = <Widget>[];

    if (active.isNotEmpty) {
      items.add(AppSectionHeader(
        title: 'Active',
        subtitle: '${active.length} in progress',
      ));
      items.addAll([
        for (final s in active)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: SessionCard(session: s, onTap: () => _open(s), onAction: (a) => _handleAction(a, s)),
          ),
      ]);
    }

    for (final group in SessionGroup.values) {
      final list = groups[group] ?? const [];
      if (list.isEmpty) continue;
      items.add(AppSectionHeader(
        title: group.label,
        subtitle: '${list.length} chats',
      ));
      items.addAll([
        for (final s in list)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: SessionCard(session: s, onTap: () => _open(s), onAction: (a) => _handleAction(a, s)),
          ),
      ]);
    }

    return items;
  }

  List<WorkspaceSession> _filtered(List<WorkspaceSession> all) {
    var list = all;
    switch (_filter) {
      case _SessionFilter.all:
        break;
      case _SessionFilter.pinned:
        list = list.where((s) => s.pinned).toList();
      case _SessionFilter.active:
        list = list.where((s) => s.status == SessionStatus.inProgress).toList();
      case _SessionFilter.archived:
        list = list.where((s) => s.archived).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.title.toLowerCase().contains(_query) ||
                (s.purpose ?? '').toLowerCase().contains(_query),
          )
          .toList();
    }
    return list;
  }

  SessionGroup _groupFor(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return SessionGroup.today;
    if (diff == 1) return SessionGroup.yesterday;
    if (diff < 7) return SessionGroup.thisWeek;
    return SessionGroup.earlier;
  }

  void _open(WorkspaceSession session) {
    widget.controller.onOpenSession?.call(session);
  }

  Future<void> _handleAction(SessionCardAction action, WorkspaceSession session) async {
    final controller = widget.controller;
    switch (action) {
      case SessionCardAction.pin:
        controller.pinSession(session);
      case SessionCardAction.archive:
        controller.archiveSession(session);
      case SessionCardAction.delete:
        final confirmed = await AppConfirmationDialog.show(
          context,
          title: 'Delete chat?',
          message:
              '"${session.title}" and its conversation will be removed from '
              'this workspace. This cannot be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (confirmed == true && mounted) {
          controller.deleteSession(session);
        }
    }
  }

  Future<void> _startNewSession() async {
    final title = await AppBottomSheet.show<String>(
      context,
      title: 'Start a new chat',
      child: _NewSessionSheet(),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    final detail = await widget.controller.createSession(title.trim());
    if (!mounted) return;
    widget.controller.onOpenSession?.call(detail.session);
  }
}

class _NewSessionSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppPromptField(
      hint: 'What are you working on?',
      autofocus: true,
      onSend: (text) => Navigator.of(context).pop(text),
    );
  }
}

class _EmptySessions extends StatelessWidget {
  const _EmptySessions({required this.onStart, required this.isSearching});

  final VoidCallback onStart;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: isSearching
          ? null
          : Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
      title: isSearching ? 'No chats found' : 'No chats yet',
      description: isSearching
          ? 'Try a different keyword or filter.'
          : 'Start a chat with Banataq and it will appear here.',
      ctaLabel: isSearching ? null : 'Start a chat',
      onCta: isSearching ? null : onStart,
    );
  }
}
