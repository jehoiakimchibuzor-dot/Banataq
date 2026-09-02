import 'package:flutter/material.dart';
import '../app_card.dart';
import '../app_divider.dart';
import '../chips/app_chip.dart';

/// A project memory entry — an editable fact the AI maintains for a project.
class MemoryCard extends StatelessWidget {
  const MemoryCard({
    super.key,
    required this.title,
    required this.content,
    this.source,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.icon = Icons.lightbulb_outline_rounded,
  });

  final String title;
  final String content;
  final String? source;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(icon: icon, size: 34, iconSize: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: textTheme.titleSmall),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  tooltip: 'Edit memory',
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: scheme.error,
                  tooltip: 'Delete memory',
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (source != null) ...[
            const SizedBox(height: 10),
            const AppDivider(hairline: true),
            const SizedBox(height: 8),
            Row(
              children: [
                AppCategoryChip(
                  label: source!,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
