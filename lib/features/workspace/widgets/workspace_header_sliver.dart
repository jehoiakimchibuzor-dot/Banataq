import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../domain/models/workspace.dart';

/// Collapsible sticky header for a workspace.
///
/// Expands to a full cover + identity block, collapses to a slim bar while
/// scrolling. Built as a pinned [SliverPersistentHeader] so the collapse is
/// directly driven by scroll offset — no animation controllers needed.
class WorkspaceHeaderSliver extends StatelessWidget {
  const WorkspaceHeaderSliver({
    super.key,
    required this.workspace,
    required this.onContinue,
    this.onBack,
    this.onTogglePin,
    this.onToggleFavourite,
    this.onSettings,
    this.onSearch,
    this.maxHeight = 220,
    this.minHeight = 64,
  });

  final Workspace workspace;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleFavourite;
  final VoidCallback? onSettings;
  final VoidCallback? onSearch;
  final double maxHeight;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    // Header is full-bleed behind the status bar; the delegate applies a
    // SafeArea, so the extents must include the top inset.
    final topInset = MediaQuery.paddingOf(context).top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _WorkspaceHeaderDelegate(
        workspace: workspace,
        onContinue: onContinue,
        onBack: onBack,
        onTogglePin: onTogglePin,
        onToggleFavourite: onToggleFavourite,
        onSettings: onSettings,
        onSearch: onSearch,
        maxHeight: maxHeight + topInset,
        minHeight: minHeight + topInset,
      ),
    );
  }
}

class _WorkspaceHeaderDelegate extends SliverPersistentHeaderDelegate {
  _WorkspaceHeaderDelegate({
    required this.workspace,
    required this.onContinue,
    this.onBack,
    this.onTogglePin,
    this.onToggleFavourite,
    this.onSettings,
    this.onSearch,
    required this.maxHeight,
    required this.minHeight,
  });

  final Workspace workspace;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleFavourite;
  final VoidCallback? onSettings;
  final VoidCallback? onSearch;
  final double maxHeight;
  final double minHeight;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _WorkspaceHeaderDelegate oldDelegate) =>
      oldDelegate.workspace != workspace ||
      oldDelegate.maxHeight != maxHeight ||
      oldDelegate.minHeight != minHeight ||
      oldDelegate.onTogglePin != onTogglePin ||
      oldDelegate.onToggleFavourite != onToggleFavourite;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.appSpacing;
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final collapsed = t > 0.55;

    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Cover(workspace: workspace, faded: t),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              return SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? spacing.xxl : spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ActionRow(
                        workspace: workspace,
                        onBack: onBack,
                        onTogglePin: onTogglePin,
                        onToggleFavourite: onToggleFavourite,
                        onSettings: onSettings,
                        onContinue: onContinue,
                        onSearch: onSearch,
                        collapsed: collapsed,
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: 1 - t,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: _ExpandedContent(
                              workspace: workspace,
                              wide: wide,
                              onContinue: onContinue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.workspace, required this.faded});
  final Workspace workspace; final double faded;
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: Opacity(opacity: (1 - faded) * 0.0, child: const SizedBox()));
  }
}

/// Top action bar. When expanded it holds back + favourite + pin + settings;
/// when collapsed the identity (emoji + name) slides in beside the actions.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.workspace,
    required this.collapsed,
    required this.onContinue,
    this.onBack,
    this.onTogglePin,
    this.onToggleFavourite,
    this.onSettings,
    this.onSearch,
  });

  final Workspace workspace;
  final bool collapsed;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onTogglePin;
  final VoidCallback? onToggleFavourite;
  final VoidCallback? onSettings;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (onBack != null)
            AppIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: onBack,
              tooltip: 'Back',
            ),
          if (collapsed) ...[
            const SizedBox(width: 4),
            _EmojiTile(
              emoji: workspace.emoji,
              progress: workspace.progress,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workspace.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    workspace.status.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ] else
            const Spacer(),
          if (!collapsed) ...[
            AppIconButton(
              icon: workspace.favourite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              onPressed: onToggleFavourite,
              tooltip: workspace.favourite ? 'Remove favourite' : 'Favourite',
              isSelected: workspace.favourite,
            ),
            const SizedBox(width: 4),
            AppIconButton(
              icon: workspace.pinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              onPressed: onTogglePin,
              tooltip: workspace.pinned ? 'Unpin' : 'Pin workspace',
              isSelected: workspace.pinned,
            ),
            const SizedBox(width: 4),
          ],
          if (collapsed) ...[
            const SizedBox(width: 4),
            AppIconButton(
              icon: Icons.arrow_forward_rounded,
              onPressed: onContinue,
              tooltip: 'Continue',
              variant: AppIconButtonVariant.filled,
            ),
          ],
          const SizedBox(width: 4),
          if (onSearch != null)
            AppIconButton(
              icon: Icons.search_rounded,
              onPressed: onSearch,
              tooltip: 'Search this workspace',
              color: scheme.onSurfaceVariant,
            ),
          const SizedBox(width: 4),
          AppIconButton(
            icon: Icons.more_horiz_rounded,
            onPressed: onSettings,
            tooltip: 'Workspace settings',
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.workspace,
    required this.wide,
    required this.onContinue,
  });

  final Workspace workspace;
  final bool wide;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _EmojiTile(emoji: workspace.emoji, progress: workspace.progress),
            SizedBox(width: wide ? spacing.md : spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusBadge(status: workspace.status),
                  const SizedBox(height: 6),
                  Text(
                    workspace.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (wide
                            ? textTheme.displaySmall
                            : textTheme.headlineMedium)
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workspace.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.lg),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppProgress.linear(
                          value: workspace.progress,
                          minHeight: 6,
                        ),
                      ),
                      if (workspace.progressLabel != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          workspace.progressLabel!,
                          style: textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${workspace.taskDone} of ${workspace.taskCount} tasks done',
                    style: textTheme.labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing.lg),
            AppButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: onContinue,
            ),
          ],
        ),
      ],
    );

    return wide
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: identity,
          )
        : identity;
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({
    required this.emoji,
    required this.progress,
    this.size = 64,
  });

  final String emoji;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(size * 0.04),
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: size * 0.05,
              backgroundColor: scheme.outlineVariant,
            ),
          ),
          Center(
            child: Container(
              width: size * 0.72,
              height: size * 0.72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(size * 0.24),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                emoji,
                style: TextStyle(fontSize: size * 0.36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final WorkspaceStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      WorkspaceStatus.active => AppBadgeTone.success,
      WorkspaceStatus.paused => AppBadgeTone.neutral,
      WorkspaceStatus.atRisk => AppBadgeTone.warning,
    };
    return AppBadge(label: status.label, tone: tone, dot: true);
  }
}
