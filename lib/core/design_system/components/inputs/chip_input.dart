import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';
import '../chips/app_chip.dart';

/// A text input that accumulates entered values as removable chips.
///
/// Pressing Enter (or the submit action, or comma) commits the current text
/// as a tag. Commonly used for memory tags and project labels.
class ChipInput extends StatefulWidget {
  const ChipInput({
    super.key,
    this.initialTags = const [],
    this.onChanged,
    this.hint = 'Type and press Enter',
    this.maxTags,
    this.enabled = true,
    this.validator,
    this.suggestions,
  });

  final List<String> initialTags;
  final ValueChanged<List<String>>? onChanged;
  final String hint;
  final int? maxTags;
  final bool enabled;
  final bool Function(String value)? validator;
  final List<String>? suggestions;

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  late final List<String> _tags = List.of(widget.initialTags);
  final _controller = TextEditingController();

  void _commit([String? raw]) {
    final value = (raw ?? _controller.text).trim();
    if (value.isEmpty) return;
    if (widget.validator?.call(value) == false) return;
    if (widget.maxTags != null && _tags.length >= widget.maxTags!) return;
    if (_tags.contains(value)) {
      _controller.clear();
      return;
    }
    setState(() {
      _tags.add(value);
      _controller.clear();
    });
    widget.onChanged?.call(List.unmodifiable(_tags));
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged?.call(List.unmodifiable(_tags));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = context.appRadius;

    final suggestions = widget.suggestions?.where((s) => !_tags.contains(s)).toList() ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(radius.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._tags.map((tag) => AppChip(
                    label: tag,
                    onDeleted: widget.enabled ? () => _remove(tag) : null,
                  )),
              if (widget.enabled)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: TextField(
                    controller: _controller,
                    enabled: widget.enabled,
                    decoration: InputDecoration(
                      hintText: _tags.isEmpty ? widget.hint : 'Add…',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(color: scheme.onSurface, fontSize: 14),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _commit,
                    onEditingComplete: () => _commit(),
                  ),
                ),
            ],
          ),
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions
                  .map((s) => AppCategoryChip(label: s, icon: Icons.add_rounded))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
