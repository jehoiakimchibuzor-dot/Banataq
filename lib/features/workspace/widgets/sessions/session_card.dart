import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_session.dart';
import '../../utils/time_ago.dart';

/// Actions available from a session card's overflow menu.
enum SessionCardAction { pin, archive, delete }

/// Card for a single session in the Sessions tab.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onAction,
    this.compact = false,
  });

  final WorkspaceSession session;
  final VoidCallback? onTap;

  /// Invoked with the requested action; null entries disable the menu.
  final void Function(SessionCardAction action)? onAction;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconTile(
                icon: _statusIcon,
                size: compact ? 36 : 40,
                iconSize: compact ? 18 : 20,
                color: _statusColor(context),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (session.purpose != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        session.purpose!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (session.pinned) ...[
                const AppBadge(
                  label: 'Pinned',
                  icon: Icons.push_pin_rounded,
                  tone: AppBadgeTone.brand,
                  compact: true,
                ),
                const SizedBox(width: 6),
              ],
              AppBadge(
                label: session.status.label,
                tone: _statusTone,
                compact: true,
              ),
            ],
          ),
          if (session.preview case final preview?) ...[
            SizedBox(height: spacing.sm),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: spacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaItem(icon: Icons.schedule_rounded, label: timeAgo(session.updatedAt)),
                    if (session.durationLabel != null)
                      _MetaItem(icon: Icons.timer_outlined, label: session.durationLabel!),
                    if (session.messageCount > 0)
                      _MetaItem(
                        icon: Icons.forum_outlined,
                        label: session.messageCount == 1
                            ? '1 message'
                            : '${session.messageCount} messages',
                      ),
                    if (session.linkedFileIds.isNotEmpty)
                      _MetaItem(
                        icon: Icons.attach_file_rounded,
                        label: '${session.linkedFileIds.length} files',
                      ),
                    if (session.linkedTaskIds.isNotEmpty)
                      _MetaItem(
                        icon: Icons.checklist_rounded,
                        label: '${session.linkedTaskIds.length} tasks',
                      ),
                  ],
                ),
              ),
              if (onAction != null)
                _ActionsMenu(
                  onAction: onAction!,
                  pinned: session.pinned,
                  archived: session.archived,
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (session.status) {
        SessionStatus.inProgress => Icons.play_arrow_rounded,
        SessionStatus.idle => Icons.pause_rounded,
        SessionStatus.completed => Icons.check_rounded,
        SessionStatus.archived => Icons.archive_rounded,
      };

  Color _statusColor(BuildContext context) => switch (session.status) {
        SessionStatus.inProgress => Theme.of(context).colorScheme.primaryContainer,
        SessionStatus.idle => Theme.of(context).colorScheme.surfaceContainerHighest,
        SessionStatus.completed => context.appSemantics.successContainer,
        SessionStatus.archived => Theme.of(context).colorScheme.surfaceContainerHighest,
      };

  AppBadgeTone get _statusTone => switch (session.status) {
        SessionStatus.inProgress => AppBadgeTone.brand,
        SessionStatus.idle => AppBadgeTone.neutral,
        SessionStatus.completed => AppBadgeTone.success,
        SessionStatus.archived => AppBadgeTone.neutral,
      };
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ActionsMenu extends StatelessWidget {
  const _ActionsMenu({
    required this.onAction,
    required this.pinned,
    required this.archived,
  });

  final void Function(SessionCardAction action) onAction;
  final bool pinned;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<SessionCardAction>(
      tooltip: 'Chat actions',
      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appRadius.sm),
      ),
      onSelected: onAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SessionCardAction.pin,
          child: _MenuItemLabel(
            icon: Icons.push_pin_outlined,
            label: pinned ? 'Unpin' : 'Pin',
          ),
        ),
        PopupMenuItem(
          value: SessionCardAction.archive,
          child: _MenuItemLabel(
            icon: Icons.archive_outlined,
            label: archived ? 'Restore' : 'Archive',
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: SessionCardAction.delete,
          child: _MenuItemLabel(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            destructive: true,
          ),
        ),
      ],
    );
  }
}

class _MenuItemLabel extends StatelessWidget {
  const _MenuItemLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
