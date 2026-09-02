import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_file.dart';

/// Recent files chips row for the Overview tab.
class RecentFilesPreview extends StatelessWidget {
  const RecentFilesPreview({
    super.key,
    required this.files,
    this.onOpen,
    this.onSeeAll,
  });

  final List<WorkspaceFile> files;
  final void Function(WorkspaceFile)? onOpen;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return AppSectionList(
      title: 'Recent files',
      actionLabel: 'See all',
      onAction: onSeeAll,
      separated: false,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
            itemBuilder: (context, i) {
              final f = files[i];
              return Material(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(radius.pill),
                child: InkWell(
                  onTap: onOpen == null ? null : () => onOpen!(f),
                  borderRadius: BorderRadius.circular(radius.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          f.type.icon,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f.name,
                          style: textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
