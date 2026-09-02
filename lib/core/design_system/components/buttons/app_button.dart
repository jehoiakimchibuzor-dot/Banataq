import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, tonal, text }

/// The universal Banataq button.
///
/// [AppButtonVariant.primary]   — filled, main call-to-action.
/// [AppButtonVariant.secondary] — outlined, alternative action.
/// [AppButtonVariant.tonal]     — softly filled, secondary emphasis.
/// [AppButtonVariant.text]      — quiet, tertiary action.
///
/// Pass [isLoading] for the loading state — the label is replaced by a
/// spinner sized to the button (the "Loading Button").
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.height,
    this.minimumSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double? height;
  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    final effective = isLoading ? null : onPressed;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        minimumSize ?? Size(fullWidth ? double.infinity : 0, height ?? 50),
      ),
    );

    final child = isLoading
        ? const _LoadingContent()
        : _LabelContent(label: label, icon: icon);

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effective,
          style: style,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effective,
          style: style,
          child: child,
        ),
      AppButtonVariant.tonal => FilledButton.tonal(
          onPressed: effective,
          style: style,
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effective,
          style: style.copyWith(
            minimumSize: WidgetStatePropertyAll(
              minimumSize ?? Size(fullWidth ? double.infinity : 0, height ?? 44),
            ),
          ),
          child: child,
        ),
    };
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 18,
      width: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: scheme.primary,
      ),
    );
  }
}

class _LabelContent extends StatelessWidget {
  const _LabelContent({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
