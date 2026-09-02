import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../app_card.dart';
import '../../animations/shimmer.dart';

/// A card-shaped skeleton. Mimics the [AppCard] layout so loading and loaded
/// states never "jump".
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    this.lines = 3,
    this.showAvatar = false,
    this.avatarSize = 40,
    this.padding = const EdgeInsets.all(16),
    this.height,
    this.radius,
  });

  final int lines;
  final bool showAvatar;
  final double avatarSize;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius ?? context.appRadius.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            SkeletonCircle(size: avatarSize),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 140, height: 14),
                const SizedBox(height: 10),
                for (var i = 0; i < (lines - 1).clamp(0, 3); i++) ...[
                  SkeletonLine(width: 220 - i * 30, height: 10),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
