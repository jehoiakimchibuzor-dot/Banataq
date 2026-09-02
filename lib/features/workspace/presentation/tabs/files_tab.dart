import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_file.dart';
import '../../widgets/common/workspace_filter_chips.dart';
import '../../widgets/files/file_detail_sheet.dart';
import '../../widgets/files/file_grid_card.dart';
import '../workspace_controller.dart';

enum _FileFilter { all, pdf, document, sheet, image }

enum _FileSort { recent, name, type }

/// Files tab â€” every document, sheet, image and link in the workspace.
///
/// Supports search, type filtering, sorting, grid/list layouts, AI file
/// summaries and add/delete/favourite/pin actions.
class FilesTab extends StatefulWidget {
  const FilesTab({super.key, required this.controller});

  final WorkspaceController controller;

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  _FileFilter _filter = _FileFilter.all;
  _FileSort _sort = _FileSort.recent;
  bool _grid = true;

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
        final all = controller.files;
        final visible = loading ? const <WorkspaceFile>[] : _filtered(all);

        final slivers = <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(spacing.md, spacing.md, spacing.md, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Files',
                              style: textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loading
                                  ? 'Loading files...'
                                  : '${all.length} files · ${all.where((f) => f.summarized).length} summarized',
                              style: textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _LayoutToggle(grid: _grid, onChanged: (v) => setState(() => _grid = v)),
                    ],
                  ),
                  SizedBox(height: spacing.md),
                  AppSearchField(
                    controller: _search,
                    hint: 'Search files...',
                    onChanged: (value) => setState(() {
                      _query = value.trim().toLowerCase();
                    }),
                  ),
                  SizedBox(height: spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: WorkspaceFilterChips(
                          options: [
                            for (final f in _FileFilter.values)
                              FilterOption(
                                label: switch (f) {
                                  _FileFilter.all => 'All',
                                  _FileFilter.pdf => 'PDF',
                                  _FileFilter.document => 'Docs',
                                  _FileFilter.sheet => 'Sheets',
                                  _FileFilter.image => 'Images',
                                },
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                          ],
                        ),
                      ),
                      _SortMenu(
                        sort: _sort,
                        onChanged: (s) => setState(() => _sort = s),
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
              child: _EmptyFiles(
                isSearching: _query.isNotEmpty || _filter != _FileFilter.all,
                onAdd: _addFile,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xxl),
              sliver: _grid
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisExtent: 168,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final f = visible[i];
                          return FileGridCard(
                            file: f,
                            onTap: () => showFileDetailSheet(context, controller, f),
                            onToggleFavourite: () =>
                                controller.toggleFileFavourite(f),
                          );
                        },
                        childCount: visible.length,
                      ),
                    )
                  : SliverList.list(
                      children: [
                        for (final f in visible)
                          Padding(
                            padding: EdgeInsets.only(bottom: spacing.sm),
                            child: FileCard(
                              name: f.name,
                              type: f.type,
                              meta: f.meta,
                              summarized: f.summarized,
                              onTap: () => showFileDetailSheet(context, controller, f),
                              onLongPress: () =>
                                  controller.toggleFileFavourite(f),
                              trailing: f.pinned
                                  ? const Icon(
                                      Icons.push_pin_rounded,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
            ),
        ];

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.refresh,
              child: CustomScrollView(
                key: const PageStorageKey('workspace-files'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: slivers,
              ),
            ),
            Positioned(
              right: spacing.md,
              bottom: spacing.md,
              child: AppFAB(
                icon: Icons.upload_file_rounded,
                label: 'Add file',
                onPressed: _addFile,
                tooltip: 'Add a file to this workspace',
              ),
            ),
          ],
        );
      },
    );
  }

  List<WorkspaceFile> _filtered(List<WorkspaceFile> all) {
    var list = all;
    switch (_filter) {
      case _FileFilter.all:
        break;
      case _FileFilter.pdf:
        list = list.where((f) => f.type == AppFileType.pdf).toList();
      case _FileFilter.document:
        list = list.where((f) => f.type == AppFileType.document).toList();
      case _FileFilter.sheet:
        list = list.where((f) => f.type == AppFileType.sheet).toList();
      case _FileFilter.image:
        list = list.where((f) => f.type == AppFileType.image).toList();
    }
    if (_query.isNotEmpty) {
      list = list
          .where(
            (f) =>
                f.name.toLowerCase().contains(_query) ||
                f.type.label.toLowerCase().contains(_query),
          )
          .toList();
    }
    switch (_sort) {
      case _FileSort.recent:
        list = List.of(list)..sort((a, b) {
            final at = a.createdAt;
            final bt = b.createdAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });
      case _FileSort.name:
        list = List.of(list)..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _FileSort.type:
        list = List.of(list)..sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    return list;
  }

  Future<void> _addFile() async {
    final result = await AppBottomSheet.show<_FileDraft>(
      context,
      title: 'Add a file',
      child: const _AddFileSheet(),
    );
    if (result == null || !mounted) return;
    widget.controller.addFile(result.name, result.type);
  }
}

class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({required this.grid, required this.onChanged});

  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(context.appRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.grid_view_rounded,
            selected: grid,
            tooltip: 'Grid view',
            onTap: () => onChanged(true),
          ),
          _ToggleButton(
            icon: Icons.view_agenda_outlined,
            selected: !grid,
            tooltip: 'List view',
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.appRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(context.appRadius.pill),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final _FileSort sort;
  final ValueChanged<_FileSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_FileSort>(
      tooltip: 'Sort files',
      initialValue: sort,
      icon: Icon(Icons.sort_rounded, color: scheme.onSurfaceVariant),
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _FileSort.recent,
          child: Text('Recently added'),
        ),
        const PopupMenuItem(
          value: _FileSort.name,
          child: Text('Name'),
        ),
        const PopupMenuItem(
          value: _FileSort.type,
          child: Text('Type'),
        ),
      ],
    );
  }
}

class _EmptyFiles extends StatelessWidget {
  const _EmptyFiles({required this.isSearching, required this.onAdd});

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
          Icons.folder_open_rounded,
          size: 42,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: isSearching ? 'No files found' : 'No files yet',
      description: isSearching
          ? 'Try a different keyword or filter.'
          : 'Add documents, sheets, images or links to keep everything in one place.',
      ctaLabel: isSearching ? null : 'Add a file',
      onCta: isSearching ? null : onAdd,
    );
  }
}

class _FileDraft {
  const _FileDraft(this.name, this.type);

  final String name;
  final AppFileType type;
}

class _AddFileSheet extends StatefulWidget {
  const _AddFileSheet();

  @override
  State<_AddFileSheet> createState() => _AddFileSheetState();
}

class _AddFileSheetState extends State<_AddFileSheet> {
  final TextEditingController _name = TextEditingController();
  AppFileType _type = AppFileType.document;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return StatefulBuilder(
      builder: (context, setState) {
        final canSubmit = _name.text.trim().isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'What kind of file is this?',
              style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in AppFileType.values)
                  AppFilterChip(
                    label: t.label,
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            SizedBox(height: spacing.md),
            AppTextField(
              controller: _name,
              label: 'File name',
              hint: 'e.g. suppliers_quote.xlsx',
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (canSubmit) _submit();
              },
            ),
            SizedBox(height: spacing.lg),
            AppButton(
              label: 'Add file',
              icon: Icons.add_rounded,
              onPressed: canSubmit ? _submit : null,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(_FileDraft(name, _type));
  }
}
