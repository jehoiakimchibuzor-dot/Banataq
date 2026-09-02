import 'package:flutter/material.dart';

/// Themed dialog helper. Use for alerts and simple content dialogs.
abstract final class AppDialog {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    List<Widget>? actions,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        icon: icon != null ? Icon(icon, size: 32) : null,
        title: Text(title),
        content: content ?? (message != null ? Text(message) : null),
        actions: actions ?? [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}
