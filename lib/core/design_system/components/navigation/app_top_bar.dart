import 'package:flutter/material.dart';

/// The branded app header. Theme-driven, transparent by default so screens
/// control their own background. Title/subtitle stack with actions on the
/// right.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.onBack,
    this.actions = const [],
    this.padding,
    this.height,
    this.centerTitle = false,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget? effectiveLeading;
    if (leading != null) {
      effectiveLeading = leading;
    } else if (onBack != null) {
      effectiveLeading = IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
      );
    } else {
      effectiveLeading = null;
    }

    return SafeArea(
      bottom: false,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            if (effectiveLeading != null) ...[
              effectiveLeading,
              if (centerTitle) const Spacer(),
            ],
            if (title != null || subtitle != null)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: centerTitle
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title!, style: textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              )
            else
              const Spacer(),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
