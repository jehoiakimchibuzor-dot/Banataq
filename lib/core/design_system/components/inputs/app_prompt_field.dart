import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

/// The AI composer — a multiline prompt field with a send affordance.
///
/// [onSend] receives the trimmed text; the field clears itself after send.
class AppPromptField extends StatefulWidget {
  const AppPromptField({
    super.key,
    this.onSend,
    this.onChanged,
    this.controller,
    this.hint = 'Ask Banataq anything...',
    this.sending = false,
    this.minLines = 1,
    this.maxLines = 4,
    this.enabled = true,
    this.actions,
    this.sendIcon = Icons.arrow_upward_rounded,
    this.autofocus = false,
  });

  final ValueChanged<String>? onSend;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String hint;
  final bool sending;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final List<Widget>? actions;
  final IconData sendIcon;
  final bool autofocus;

  @override
  State<AppPromptField> createState() => _AppPromptFieldState();
}

class _AppPromptFieldState extends State<AppPromptField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  bool get _canSend => _controller.text.trim().isNotEmpty && !widget.sending;

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.sending) return;
    _controller.clear();
    widget.onSend?.call(text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = context.appRadius;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius.xxl),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.actions != null && widget.actions!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(children: widget.actions!),
            ),
          ],
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              enabled: widget.enabled,
              textInputAction: TextInputAction.newline,
              onChanged: (value) {
                widget.onChanged?.call(value);
                setState(() {});
              },
              onSubmitted: widget.minLines == 1 ? (_) => _submit() : null,
              style: TextStyle(color: scheme.onSurface, fontSize: 15),
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: IconButton.filled(
              onPressed: _canSend ? _submit : null,
              icon: widget.sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Icon(widget.sendIcon),
              tooltip: 'Send',
            ),
          ),
        ],
      ),
    );
  }
}
