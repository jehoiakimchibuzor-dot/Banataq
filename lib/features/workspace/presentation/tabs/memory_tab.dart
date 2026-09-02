import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_memory.dart';
import '../../widgets/common/workspace_filter_chips.dart';
import '../workspace_controller.dart';

/// Memory tab — everything Banataq remembers about the workspace.
///
/// Supports search, category filtering, pinned-on-top grouping and
/// add/edit/delete of memory entries.
class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<MemoryTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  MemoryCategory? _category;

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
        final all = controller.memories;
        final visible = loading ? const <WorkspaceMemory>[] : _filtered(all);

        final slivers = <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memory',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loading
                        ? 'Loading memory...'
                        : '${all.length} memories · ${all.where((m) => m.pinned).length} pinned',
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  SizedBox(height: spacing.md),
                  AppSearchField(
                    controller: _search,
                    hint: 'Search memory...',
                    onChanged: (value) => setState(() {
                      _query = value.trim().toLowerCase();
                    }),
                  ),
                  SizedBox(height: spacing.sm),
                  WorkspaceFilterChips(
                    options: [
                      FilterOption(
                        label: 'All',
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      for (final c in MemoryCategory.values)
                        FilterOption(
                          label: c.label,
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = c),
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
              child: _EmptyMemory(
                isSearching: _query.isNotEmpty || _category != null,
                onAdd: _addMemory,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xxl),
              sliver: SliverList.list(children: _buildSections(visible)),
            ),
        ];

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refresh,
              child: CustomScrollView(
                key: const PageStorageKey('workspace-memory'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
              ),
            ),
            Positioned(
              right: spacing.md,
              bottom: spacing.md,
              child: AppFAB(
                icon: Icons.add_rounded,
                label: 'Add memory',
                onPressed: _addMemory,
                tooltip: 'Save a memory to this workspace',
              ),
            ),
          ],
        );
      },
    );
  }

  List<WorkspaceMemory> _filtered(List<WorkspaceMemory> all) {
    var list = all;
    if (_category != null) {
      list = list.where((m) => m.category == _category).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
            (m) =>
                m.title.toLowerCase().contains(_query) ||
                m.content.toLowerCase().contains(_query),
          )
          .toList();
    }
    return list;
  }

  List<Widget> _buildSections(List<WorkspaceMemory> visible) {
    final spacing = context.appSpacing;
    final pinned = visible.where((m) => m.pinned).toList();
    final rest = visible.where((m) => !m.pinned).toList();
    final items = <Widget>[];

    void addBlock(String title, String? subtitle, List<WorkspaceMemory> list) {
      if (list.isEmpty) return;
      items.add(AppSectionHeader(title: title, subtitle: subtitle));
      const SizedBox(height: 4);
      items.addAll([
        for (final m in list)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: MemoryCard(
              title: m.title,
              content: m.content,
              source: m.source,
              icon: _iconFor(m.category),
              onTap: () => _editMemory(m),
              onEdit: () => _editMemory(m),
              onDelete: () => _confirmDelete(m),
            ),
          ),
      ]);
    }

    if (_category == null && _query.isEmpty) {
      addBlock('Pinned', '${pinned.length} saved', pinned);
    }
    for (final c in MemoryCategory.values) {
      final byCategory = rest.where((m) => m.category == c).toList();
      if (byCategory.isEmpty) continue;
      addBlock(c.label, '${byCategory.length} ${byCategory.length == 1 ? 'memory' : 'memories'}', byCategory);
    }

    return items;
  }

  IconData _iconFor(MemoryCategory category) => switch (category) {
        MemoryCategory.preferences => Icons.tune_rounded,
        MemoryCategory.contacts => Icons.person_outline_rounded,
        MemoryCategory.goals => Icons.flag_outlined,
        MemoryCategory.decisions => Icons.rule_rounded,
        MemoryCategory.context => Icons.info_outline_rounded,
        MemoryCategory.rules => Icons.policy_outlined,
      };

  Future<void> _addMemory() async {
    final draft = await showMemoryEditorSheet(context);
    if (draft == null || !mounted) return;
    widget.controller.addMemory(draft.title, draft.content, draft.category);
  }

  Future<void> _editMemory(WorkspaceMemory memory) async {
    final draft = await showMemoryEditorSheet(context, memory: memory);
    if (draft == null || !mounted) return;
    widget.controller.updateMemory(
      memory,
      title: draft.title,
      content: draft.content,
      category: draft.category,
    );
  }

  Future<void> _confirmDelete(WorkspaceMemory memory) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Delete memory?',
      message: '"${memory.title}" will be forgotten for this workspace.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true && mounted) {
      widget.controller.deleteMemory(memory);
    }
  }
}

class _EmptyMemory extends StatelessWidget {
  const _EmptyMemory({required this.isSearching, required this.onAdd});

  final bool isSearching;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          Icons.psychology_outlined,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: isSearching ? 'No memories found' : 'Nothing saved yet',
      description: isSearching
          ? 'Try a different keyword or filter.'
          : 'Save preferences, contacts and decisions and Banataq will '
              'remember them across sessions.',
      ctaLabel: isSearching ? null : 'Add a memory',
      onCta: isSearching ? null : onAdd,
    );
  }
}

class MemoryDraft {
  const MemoryDraft(this.title, this.content, this.category);

  final String title;
  final String content;
  final MemoryCategory category;
}

/// Opens the add/edit memory sheet. Returns a draft when saved.
Future<MemoryDraft?> showMemoryEditorSheet(
  BuildContext context, {
  WorkspaceMemory? memory,
}) {
  return AppBottomSheet.show<MemoryDraft>(
    context,
    title: memory == null ? 'Add memory' : 'Edit memory',
    child: _MemoryEditorSheet(memory: memory),
  );
}

class _MemoryEditorSheet extends StatefulWidget {
  const _MemoryEditorSheet({this.memory});

  final WorkspaceMemory? memory;

  @override
  State<_MemoryEditorSheet> createState() => _MemoryEditorSheetState();
}

class _MemoryEditorSheetState extends State<_MemoryEditorSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.memory?.title ?? '');
  late final TextEditingController _content =
      TextEditingController(text: widget.memory?.content ?? '');
  late MemoryCategory _category = widget.memory?.category ?? MemoryCategory.context;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return StatefulBuilder(
      builder: (context, setState) {
        final canSubmit =
            _title.text.trim().isNotEmpty && _content.text.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Category',
              style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in MemoryCategory.values)
                  AppFilterChip(
                    label: c.label,
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              controller: _title,
              label: 'Title',
              hint: 'e.g. Preferred currency',
              autofocus: widget.memory == null,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: spacing.sm),
            AppTextField(
              controller: _content,
              label: 'What should Banataq remember?',
              hint: 'Always present supplier quotes in Naira.',
              maxLines: 3,
              minLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: spacing.lg),
            AppButton(
              label: widget.memory == null ? 'Save memory' : 'Save changes',
              icon: Icons.save_rounded,
              onPressed: canSubmit ? _submit : null,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    Navigator.of(context).pop(
      MemoryDraft(
        _title.text.trim(),
        _content.text.trim(),
        _category,
      ),
    );
  }
}
