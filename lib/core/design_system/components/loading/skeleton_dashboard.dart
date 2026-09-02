import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../../animations/shimmer.dart';
import 'skeleton_card.dart';
import 'skeleton_list.dart';

/// Full-dashboard skeleton mirroring the Home layout: header line, hero
/// continue card, quick-action tiles, and a section list.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: 220, height: 22),
        const SizedBox(height: 8),
        SkeletonLine(width: 160, height: 12),
        SizedBox(height: spacing.lg),
        const SkeletonCard(lines: 3, showAvatar: true, height: 170),
        SizedBox(height: spacing.lg),
        if (!compact) ...[
          SkeletonLine(width: 120, height: 14),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(context.appRadius.md),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 10),
              ],
            ],
          ),
          SizedBox(height: spacing.lg),
        ],
        SkeletonLine(width: 120, height: 14),
        SizedBox(height: spacing.sm),
        SkeletonList(count: compact ? 2 : 3),
      ],
    );
  }
}
