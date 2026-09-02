import 'package:flutter/material.dart';
import '../app_divider.dart';

/// Themed bottom sheet helper + container for consistent modals.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    Widget? header,
    List<Widget>? actions,
    bool scrollControlled = true,
    bool isDismissible = true,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: scrollControlled,
      isDismissible: isDismissible,
      showDragHandle: showDragHandle,
      useSafeArea: true,
      builder: (context) => AppBottomSheetContainer(
        title: title,
        header: header,
        actions: actions,
        child: child,
      ),
    );
  }
}

/// Scrollable sheet body with a themed header. Use directly with
/// [showModalBottomSheet] if you need full layout control.
class AppBottomSheetContainer extends StatelessWidget {
  const AppBottomSheetContainer({
    super.key,
    this.title,
    this.header,
    this.actions,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 20),
  });

  final String? title;
  final Widget? header;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null || header != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: header ??
                Row(
                  children: [
                    Expanded(
                      child: Text(title!, style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                    ),
                  ],
                ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: AppDivider(hairline: true),
          ),
        ],
        Flexible(
          child: SingleChildScrollView(
            padding: padding,
            child: child,
          ),
        ),
        if (actions != null && actions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ),
      ],
    );
  }
}
