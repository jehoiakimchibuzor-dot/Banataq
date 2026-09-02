import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';

/// Prominent "Continue where you left off" card.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    this.title,
    this.snippet,
    this.progress,
    this.progressLabel,
    this.onContinue,
  });

  final String? title;
  final String? snippet;
  final double? progress;
  final String? progressLabel;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = context.appRadius;

    final t = title;
    if (t == null) return const SizedBox.shrink();

    return AppCard(
      onTap: onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(radius.lg),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue where you left off',
                      style: textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppIconButton(
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
                tooltip: 'Continue',
                variant: AppIconButtonVariant.filled,
              ),
            ],
          ),
          if (snippet != null) ...[
            const SizedBox(height: 12),
            Text(
              snippet!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppProgress.linear(
                    value: progress,
                    minHeight: 6,
                  ),
                ),
                if (progressLabel != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    progressLabel!,
                    style: textTheme.labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
