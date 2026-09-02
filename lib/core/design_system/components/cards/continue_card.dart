import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../../animations/card_press.dart';
import '../app_card.dart';

/// The hero "resume-first" card — the single most valuable thing to pick back
/// up. Only one of these should ever be on screen.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.title,
    required this.onContinue,
    this.snippet,
    this.progress,
    this.progressLabel,
    this.contextLabel,
    this.emoji,
    this.icon,
    this.ctaLabel = 'Continue',
    this.onDismiss,
  });

  final String title;
  final String? snippet;
  final double? progress;
  final String? progressLabel;
  final String? contextLabel;
  final String? emoji;
  final IconData? icon;
  final String ctaLabel;
  final VoidCallback onContinue;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = context.appRadius;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(radius.xl),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: CardPress(
        onTap: onContinue,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconTile(icon: icon, emoji: emoji, size: 48, color: scheme.primaryContainer),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (contextLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              contextLabel!.toUpperCase(),
                              style: textTheme.labelSmall
                                  ?.copyWith(color: scheme.primary, letterSpacing: 0.6),
                            ),
                          ),
                        Text(title, style: textTheme.titleLarge),
                        if (snippet != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            snippet!,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (progress != null)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  if (progressLabel != null) ...[
                    const SizedBox(width: 10),
                    Text(progressLabel!, style: textTheme.labelMedium),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onContinue,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ctaLabel),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
