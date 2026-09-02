import 'package:flutter/material.dart';
import 'app_divider.dart';
import 'navigation/app_section_header.dart';

/// A reusable section list: header (title/subtitle/action) + items with
/// optional separators and footer.
class AppSectionList extends StatelessWidget {
  const AppSectionList({
    super.key,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.children = const [],
    this.separated = true,
    this.dividerIndent = 16,
    this.footer,
    this.padding = EdgeInsets.zero,
  });

  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;
  final bool separated;
  final double dividerIndent;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            AppSectionHeader(
              title: title!,
              subtitle: subtitle,
              actionLabel: actionLabel,
              onAction: onAction,
            ),
          if (children.isNotEmpty) ...[
            if (title != null) const SizedBox(height: 4),
            ...separated
                ? _withDividers(context)
                : children,
          ],
          if (footer != null) ...[
            if (children.isNotEmpty) const SizedBox(height: 4),
            footer!,
          ],
        ],
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      for (var i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: dividerIndent),
            child: AppDivider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
      ],
    ];
  }
}
