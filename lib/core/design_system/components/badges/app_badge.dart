import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

enum AppBadgeTone { neutral, brand, success, warning, danger, info, ai }

/// Small status pill. Base for the badge family — tint, foreground and icon
/// are all derived from the theme so no color is hardcoded.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
    this.dot = false,
    this.compact = false,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;
  final bool dot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.appSemantics;
    final radius = context.appRadius;

    final (bg, fg) = switch (tone) {
      AppBadgeTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
      AppBadgeTone.brand => (scheme.primaryContainer, scheme.onPrimaryContainer),
      AppBadgeTone.success => (semantics.successContainer, semantics.success),
      AppBadgeTone.warning => (semantics.warningContainer, semantics.warning),
      AppBadgeTone.danger => (semantics.dangerContainer, semantics.danger),
      AppBadgeTone.info => (semantics.infoContainer, semantics.info),
      AppBadgeTone.ai => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };

    final iconSize = compact ? 12.0 : 14.0;
    final fontSize = compact ? 10.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral/brand status indicator (optionally with a live dot).
class StatusBadge extends AppBadge {
  const StatusBadge({
    super.key,
    required super.label,
    super.icon,
    super.dot,
    super.compact,
    super.tone = AppBadgeTone.neutral,
  });
}

/// Displays completion as a tiny inline progress bar plus label.
class ProgressBadge extends AppBadge {
  const ProgressBadge({
    super.key,
    required super.label,
    required this.progress,
    super.compact = true,
  }) : super(icon: Icons.timelapse_rounded, tone: AppBadgeTone.brand);

  final double progress;
}

/// Marks AI-generated content.
class AiBadge extends AppBadge {
  const AiBadge({
    super.key,
    super.label = 'AI',
    super.icon = Icons.auto_awesome_rounded,
    super.compact = false,
  }) : super(tone: AppBadgeTone.ai);
}

class SuccessBadge extends AppBadge {
  const SuccessBadge({
    super.key,
    required super.label,
    super.icon,
    super.dot,
    super.compact,
  }) : super(tone: AppBadgeTone.success);
}

class WarningBadge extends AppBadge {
  const WarningBadge({
    super.key,
    required super.label,
    super.icon,
    super.dot,
    super.compact,
  }) : super(tone: AppBadgeTone.warning);
}
