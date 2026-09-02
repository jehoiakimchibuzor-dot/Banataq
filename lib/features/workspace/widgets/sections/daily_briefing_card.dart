import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_overview.dart';

/// The workspace's "Today's Briefing" — a compact, AI-authored status summary
/// rendered as a distinct, clearly-labeled card.
class DailyBriefingCard extends StatelessWidget {
  const DailyBriefingCard({
    super.key,
    required this.lines,
    this.onRefresh,
  });

  final List<BriefingLine> lines;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;
    final radius = context.appRadius;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.55),
            scheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(radius.xl),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiBadge(label: 'Today'),
              const Spacer(),
              if (onRefresh != null)
                AppIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: onRefresh,
                  tooltip: 'Regenerate briefing',
                  size: 18,
                ),
            ],
          ),
          SizedBox(height: spacing.sm),
          for (final line in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (line.icon != null) ...[
                  Text(
                    line.icon!,
                    style: TextStyle(fontSize: 12, color: scheme.primary),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    line.text,
                    style: textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: line.highlight
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                      fontWeight: line.highlight ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
