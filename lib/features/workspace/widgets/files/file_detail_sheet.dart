import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_file.dart';
import '../../presentation/workspace_controller.dart';

/// Opens the file detail sheet for [file].
Future<void> showFileDetailSheet(
  BuildContext context,
  WorkspaceController controller,
  WorkspaceFile file,
) {
  return AppBottomSheet.show<void>(
    context,
    title: 'File details',
    child: _FileDetailSheet(controller: controller, file: file),
  );
}

/// Sheet showing a file's info, AI summary (or a way to generate one) and
/// management actions.
class _FileDetailSheet extends StatelessWidget {
  const _FileDetailSheet({required this.controller, required this.file});

  final WorkspaceController controller;
  final WorkspaceFile file;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final matches = controller.files.where((f) => f.id == file.id);
        final current = matches.isEmpty ? null : matches.first;
        final f = current ?? file;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconTile(
                  icon: f.type.icon,
                  size: 48,
                  iconSize: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${f.type.label} · ${f.meta ?? '—'}',
                        style: textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (f.pinned)
                  const AppBadge(
                    label: 'Pinned',
                    icon: Icons.push_pin_rounded,
                    compact: true,
                    tone: AppBadgeTone.brand,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryBlock(controller: controller, file: f),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: f.favourite ? 'Unfavourite' : 'Favourite',
                  icon: f.favourite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  onPressed: () => controller.toggleFileFavourite(f),
                  variant: AppButtonVariant.tonal,
                  height: 40,
                ),
                AppButton(
                  label: f.pinned ? 'Unpin' : 'Pin',
                  icon: f.pinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  onPressed: () => controller.toggleFilePinned(f),
                  variant: AppButtonVariant.tonal,
                  height: 40,
                ),
                AppButton(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _confirmDelete(context),
                  variant: AppButtonVariant.text,
                  height: 40,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppConfirmationDialog.show(
      context,
      title: 'Delete file?',
      message: '"${file.name}" will be removed from this workspace.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      controller.deleteFile(file);
      Navigator.of(context).pop();
    }
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.controller, required this.file});

  final WorkspaceController controller;
  final WorkspaceFile file;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return AppCard(
      padding: const EdgeInsets.all(14),
      color: scheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiBadge(label: 'AI Summary', compact: true),
              const Spacer(),
              if (file.summarized)
                TextButton.icon(
                  onPressed: () => controller.summarizeFile(file),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Regenerate'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (file.summarized && file.summary != null)
            Text(
              file.summary!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.summarized
                      ? 'Summary is being prepared…'
                      : 'No summary yet. Let Banataq read this file and pull '
                          'out the key points.',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: spacing.sm),
                AppButton(
                  label: file.summarized
                      ? 'Retry summary'
                      : 'Summarize this file',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () => controller.summarizeFile(file),
                  variant: AppButtonVariant.tonal,
                  height: 40,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
