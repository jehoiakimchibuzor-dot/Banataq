import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_file.dart';

/// Square-ish grid card for a workspace file.
class FileGridCard extends StatelessWidget {
  const FileGridCard({
    super.key,
    required this.file,
    this.onTap,
    this.onToggleFavourite,
  });

  final WorkspaceFile file;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(
                icon: file.type.icon,
                size: 38,
                iconSize: 19,
              ),
              const Spacer(),
              if (onToggleFavourite != null)
                InkWell(
                  onTap: onToggleFavourite,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      file.favourite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 18,
                      color: file.favourite
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  file.meta ?? file.type.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (file.summarized || file.pinned) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (file.summarized)
                  const AiBadge(label: 'Summarized', compact: true),
                if (file.pinned)
                  const AppBadge(
                    label: 'Pinned',
                    icon: Icons.push_pin_rounded,
                    compact: true,
                    tone: AppBadgeTone.brand,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
