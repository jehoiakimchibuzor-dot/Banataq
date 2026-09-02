import 'package:flutter/material.dart';
import '../app_card.dart';
import '../badges/app_badge.dart';

/// File categories used by [FileCard] to pick icons and labels.
enum AppFileType { pdf, image, audio, document, sheet, link, code, unknown }

extension AppFileTypeX on AppFileType {
  IconData get icon => switch (this) {
        AppFileType.pdf => Icons.picture_as_pdf_outlined,
        AppFileType.image => Icons.image_outlined,
        AppFileType.audio => Icons.graphic_eq_rounded,
        AppFileType.document => Icons.description_outlined,
        AppFileType.sheet => Icons.table_chart_outlined,
        AppFileType.link => Icons.link_rounded,
        AppFileType.code => Icons.code_rounded,
        AppFileType.unknown => Icons.insert_drive_file_outlined,
      };

  String get label => switch (this) {
        AppFileType.pdf => 'PDF',
        AppFileType.image => 'Image',
        AppFileType.audio => 'Audio',
        AppFileType.document => 'Document',
        AppFileType.sheet => 'Sheet',
        AppFileType.link => 'Link',
        AppFileType.code => 'Code',
        AppFileType.unknown => 'File',
      };
}

/// A file artifact card with an AI summary badge and an action bar entry.
class FileCard extends StatelessWidget {
  const FileCard({
    super.key,
    required this.name,
    required this.type,
    this.meta,
    this.onTap,
    this.onLongPress,
    this.summarized = false,
    this.thumbnail,
    this.trailing,
  });

  final String name;
  final AppFileType type;
  final String? meta;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool summarized;
  final Widget? thumbnail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(12),
      outlined: true,
      child: Row(
        children: [
          if (thumbnail != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 40, height: 40, child: thumbnail),
            ),
          ] else
            AppIconTile(icon: type.icon, size: 40, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta != null)
                  Text(
                    meta!,
                    style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (summarized) ...[
            const AiBadge(label: 'Summarized', compact: true),
            const SizedBox(width: 8),
          ],
          ?trailing,
        ],
      ),
    );
  }
}
