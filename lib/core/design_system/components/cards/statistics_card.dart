import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../../theme/app_theme_extensions.dart';
import '../app_card.dart';

/// A compact KPI tile — big value, small label, optional trend delta.
class StatisticsCard extends StatelessWidget {
  const StatisticsCard({
    super.key,
    required this.value,
    required this.label,
    this.delta,
    this.deltaDirection = TrendDirection.up,
    this.icon,
    this.tone = StatusTone.info,
    this.onTap,
  });

  final String value;
  final String label;
  final String? delta;
  final TrendDirection deltaDirection;
  final IconData? icon;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantics = context.appSemantics;
    final accent = semantics.foregroundFor(tone);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: scheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: textTheme.headlineSmall),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  deltaDirection == TrendDirection.up
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: deltaDirection == TrendDirection.up
                      ? semantics.success
                      : semantics.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  delta!,
                  style: textTheme.labelSmall?.copyWith(
                    color: deltaDirection == TrendDirection.up
                        ? semantics.success
                        : semantics.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum TrendDirection { up, down }
