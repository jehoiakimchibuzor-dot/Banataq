import 'package:flutter/material.dart';
import '../theme/app_theme_context.dart';
import 'buttons/app_button.dart';

/// Reusable empty state: icon, title, description and optional CTA.
///
/// Every empty surface should carry an action — never just a sad sentence.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.description,
    this.ctaLabel,
    this.onCta,
    this.secondaryAction,
    this.compact = false,
    this.padding,
    this.iconColor,
    this.iconBackground,
  });

  /// Custom illustration widget (overrides [icon]).
  final Widget? icon;
  final String title;
  final String? description;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Widget? secondaryAction;
  final bool compact;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;
    final secondary = secondaryAction;

    return Center(
      child: Padding(
        padding: padding ?? EdgeInsets.all(compact ? spacing.lg : spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              icon!
            else
              Container(
                width: compact ? 64 : 88,
                height: compact ? 64 : 88,
                decoration: BoxDecoration(
                  color: iconBackground ?? scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(compact ? 18 : 24),
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: compact ? 30 : 42,
                  color: iconColor ?? scheme.primary,
                ),
              ),
            SizedBox(height: compact ? spacing.md : spacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: compact ? textTheme.titleMedium : textTheme.titleLarge,
            ),
            if (description != null) ...[
              SizedBox(height: spacing.xs),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (ctaLabel != null && onCta != null) ...[
              SizedBox(height: spacing.lg),
              AppButton(label: ctaLabel!, onPressed: onCta),
            ],
            if (secondary != null) ...[
              SizedBox(height: spacing.sm),
              secondary,
            ],
          ],
        ),
      ),
    );
  }
}
