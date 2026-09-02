import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

enum AppSnackbarType { info, success, error, warning }

/// Themed snackbar helper. Use instead of raw [SnackBar] so styling stays
/// consistent. Colors map to semantic tones automatically.
abstract final class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    final scheme = Theme.of(context).colorScheme;
    final semantics = context.appSemantics;

    final (icon, color) = switch (type) {
      AppSnackbarType.info => (Icons.info_outline_rounded, scheme.primary),
      AppSnackbarType.success => (Icons.check_circle_outline_rounded, semantics.success),
      AppSnackbarType.error => (Icons.error_outline_rounded, semantics.danger),
      AppSnackbarType.warning => (Icons.warning_amber_rounded, semantics.warning),
    };

    final snackBar = SnackBar(
      duration: duration,
      content: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction ?? () {},
              textColor: color,
            )
          : null,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
