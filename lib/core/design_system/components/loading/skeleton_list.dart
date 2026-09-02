import 'package:flutter/material.dart';
import '../../animations/shimmer.dart';

/// A list of row skeletons — avatar + two lines each.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 5,
    this.avatarSize = 40,
    this.separatorHeight = 16,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final int count;
  final double avatarSize;
  final double separatorHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            _SkeletonRow(avatarSize: avatarSize),
            if (i < count - 1) SizedBox(height: separatorHeight),
          ],
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.avatarSize});

  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SkeletonCircle(size: avatarSize),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonLine(width: 160, height: 13),
              SizedBox(height: 8),
              SkeletonLine(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
