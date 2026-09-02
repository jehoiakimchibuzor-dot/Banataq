import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_session.dart';

/// Recent sessions strip for the Overview tab.
class RecentSessionsPreview extends StatelessWidget {
  const RecentSessionsPreview({
    super.key,
    required this.sessions,
    this.onOpen,
    this.onSeeAll,
  });

  final List<WorkspaceSession> sessions;
  final void Function(WorkspaceSession)? onOpen;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return AppSectionList(
      title: 'Recent chats',
      actionLabel: 'See all',
      onAction: onSeeAll,
      separated: false,
      children: [
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sessions.length,
            separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
            itemBuilder: (context, i) {
              final s = sessions[i];
              return SizedBox(
                width: 260,
                child: AppCard(
                  onTap: onOpen == null ? null : () => onOpen!(s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (s.pinned) ...[
                            Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          AppBadge(
                            label: s.active ? 'In progress' : 'Completed',
                            tone: s.active
                                ? AppBadgeTone.brand
                                : AppBadgeTone.success,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        s.summary ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(s.updatedAt),
                        style: textTheme.labelSmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: radius.xs),
      ],
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }
}
