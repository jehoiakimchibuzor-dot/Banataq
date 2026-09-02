import 'package:flutter/material.dart';
import '../../theme/app_theme_context.dart';

/// Global search field with a clear affordance. Opens from the top bar and
/// is typically paired with a full-screen search overlay.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.leading,
    this.trailing,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final Widget? leading;
  final Widget? trailing;
  final FocusNode? focusNode;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = context.appRadius;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius.pill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onChanged: (value) {
          widget.onChanged?.call(value);
          setState(() {});
        },
        onSubmitted: widget.onSubmitted,
        style: TextStyle(color: scheme.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: widget.leading ?? Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Clear search',
                )
              : widget.trailing,
        ),
      ),
    );
  }
}
