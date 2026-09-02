import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'syntax_highlighter.dart';

class CodeBlock extends StatelessWidget {
  final String code;
  final String? language;

  const CodeBlock({super.key, required this.code, this.language});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final langLabel = (language ?? '').isNotEmpty ? language : 'code';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, scheme, langLabel!),
          _codeBody(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme, String lang) {
    final muted = scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: scheme.surfaceContainerHigh,
      child: Row(
        children: [
          Icon(Icons.code_rounded, size: 14, color: muted),
          const SizedBox(width: 6),
          Text(lang, style: TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Copied'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 12, color: muted),
                  const SizedBox(width: 4),
                  Text('Copy', style: TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeBody(BuildContext context) {
    final spans = SyntaxHighlighter.highlight(
      code,
      language,
      Theme.of(context).brightness,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(14),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
          children: spans,
        ),
      ),
    );
  }
}
