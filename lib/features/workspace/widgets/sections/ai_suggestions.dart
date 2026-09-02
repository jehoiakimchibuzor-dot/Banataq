import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace_suggestion.dart';
/// AI-authored suggestion chips.
class AiSuggestions extends StatelessWidget {
  const AiSuggestions({
    super.key,
    required this.suggestions,
    this.onApply,
    this.onDismiss,
  });

  final List<WorkspaceSuggestion> suggestions;
  final void Function(WorkspaceSuggestion)? onApply;
  final void Function(WorkspaceSuggestion)? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return AppSectionList(
      title: 'Suggested next steps',
      separated: false,
      children: [
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
            itemBuilder: (context, i) {
              final s = suggestions[i];
              return SizedBox(
                width: 236,
                child: Material(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(context.appRadius.lg),
                  child: InkWell(
                    onTap: onApply == null ? null : () => onApply!(s),
                    borderRadius: BorderRadius.circular(context.appRadius.lg),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: spacing.sm,
                        right: spacing.xxs,
                        top: spacing.sm,
                        bottom: spacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(s.icon, size: 20, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (onDismiss != null)
                            InkWell(
                              onTap: () => onDismiss!(s),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
