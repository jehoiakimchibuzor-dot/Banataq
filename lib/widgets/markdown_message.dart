import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'code_block.dart';

class MarkdownMessage extends StatelessWidget {
  final String text;

  const MarkdownMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    return MarkdownBody(
      data: text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: onSurface, height: 1.4),
        h2: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: onSurface, height: 1.4),
        h3: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface, height: 1.4),
        p: TextStyle(fontSize: 14, color: onSurface, height: 1.6),
        listBullet: TextStyle(fontSize: 14, color: scheme.primary, height: 1.6),
        strong: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
        em: TextStyle(fontStyle: FontStyle.italic, color: onSurface.withValues(alpha: 0.85)),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: scheme.secondary,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: scheme.primary.withValues(alpha: 0.5), width: 3)),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        tableBorder: TableBorder.all(color: scheme.outlineVariant),
        tableHead: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
        tableBody: TextStyle(color: scheme.onSurfaceVariant),
        del: TextStyle(decoration: TextDecoration.lineThrough, color: scheme.onSurfaceVariant),
        a: TextStyle(color: scheme.primary, decoration: TextDecoration.underline),
      ),
      builders: {
        'pre': _CodeBlockBuilder(),
      },
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.textContent.isEmpty) return null;
    String? lang;
    if (element.attributes.containsKey('class')) {
      lang = element.attributes['class']!.replaceFirst('language-', '');
    }
    return CodeBlock(code: element.textContent, language: lang);
  }
}
