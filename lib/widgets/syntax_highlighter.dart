import 'package:flutter/material.dart';

class SyntaxHighlighter {
  static const _keywords = {
    'dart': ['import', 'class', 'void', 'final', 'const', 'var', 'if', 'else', 'for', 'while', 'return', 'this', 'super', 'extends', 'implements', 'with', 'mixin', 'abstract', 'static', 'required', 'factory', 'late', 'async', 'await', 'Future', 'Stream', 'typedef', 'enum', 'switch', 'case', 'break', 'continue', 'try', 'catch', 'throw', 'new', 'true', 'false', 'null', 'in', 'is', 'as', 'on'],
    'python': ['import', 'from', 'class', 'def', 'if', 'elif', 'else', 'for', 'while', 'return', 'yield', 'async', 'await', 'try', 'except', 'finally', 'raise', 'with', 'as', 'in', 'not', 'and', 'or', 'True', 'False', 'None', 'self', 'lambda', 'pass', 'break', 'continue', 'global', 'nonlocal', 'print'],
    'javascript': ['import', 'export', 'from', 'const', 'let', 'var', 'function', 'class', 'if', 'else', 'for', 'while', 'do', 'return', 'async', 'await', 'try', 'catch', 'throw', 'new', 'this', 'typeof', 'instanceof', 'true', 'false', 'null', 'undefined', 'switch', 'case', 'break', 'continue', 'default', 'yield', 'import', 'export', 'require', 'console'],
    'typescript': ['import', 'export', 'from', 'interface', 'type', 'const', 'let', 'var', 'function', 'class', 'if', 'else', 'for', 'while', 'return', 'async', 'await', 'try', 'catch', 'throw', 'new', 'this', 'true', 'false', 'null', 'undefined', 'enum', 'switch', 'case', 'break', 'continue', 'implements', 'extends', 'readonly', 'public', 'private', 'protected', 'static', 'abstract', 'as', 'in', 'keyof'],
    'html': ['<!DOCTYPE', 'html', 'head', 'body', 'title', 'meta', 'div', 'span', 'p', 'a', 'img', 'ul', 'ol', 'li', 'table', 'tr', 'td', 'th', 'form', 'input', 'button', 'select', 'option', 'textarea', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'footer', 'nav', 'section', 'article', 'main', 'script', 'style', 'link', 'br', 'hr', 'strong', 'em', 'b', 'i', 'u', 'class', 'id', 'href', 'src', 'alt', 'type', 'name', 'value', 'placeholder', 'onclick', 'style', 'lang', 'charset'],
    'css': ['@import', '@media', '@keyframes', '@font-face', 'body', 'html', 'div', 'span', 'p', 'a', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'table', 'tr', 'td', 'th', 'img', 'form', 'input', 'button', 'margin', 'padding', 'color', 'background', 'border', 'display', 'position', 'width', 'height', 'font', 'text', 'flex', 'grid', 'align', 'justify', 'transform', 'transition', 'animation', 'opacity', 'overflow', 'z-index', 'content', 'box', 'shadow', 'important'],
    'json': ['true', 'false', 'null'],
    'yaml': ['true', 'false', 'yes', 'no', 'on', 'off', 'null', 'name', 'version', 'description', 'dependencies', 'dev_dependencies', 'environment', 'flutter', 'sdk', 'import', 'export', 'on'],
    'bash': ['echo', 'export', 'source', 'if', 'then', 'else', 'fi', 'for', 'while', 'do', 'done', 'return', 'exit', 'cd', 'ls', 'cp', 'mv', 'rm', 'mkdir', 'touch', 'cat', 'grep', 'find', 'chmod', 'chown', 'sudo', 'apt', 'pip', 'npm', 'yarn', 'flutter', 'dart', 'git', 'docker', 'true', 'false'],
    'sql': ['SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'CREATE', 'TABLE', 'ALTER', 'DROP', 'INDEX', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'ON', 'AND', 'OR', 'NOT', 'IN', 'BETWEEN', 'LIKE', 'ORDER', 'BY', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET', 'AS', 'DISTINCT', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'NULL', 'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'CASCADE', 'UNION', 'ALL', 'EXISTS', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END', 'ASC', 'DESC'],
  };

  /// Dark-theme palette (soft pastels on near-black code surfaces).
  static const _darkColors = {
    'keyword': Color(0xFFc792ea),
    'string': Color(0xFFc3e88d),
    'number': Color(0xFFf78c6c),
    'comment': Color(0xFF8a93a3),
    'punctuation': Color(0xFF89ddff),
    'builtin': Color(0xFF82aaff),
    'plain': Color(0xFFe6e9ef),
  };

  /// Light-theme palette (deep inks on near-white code surfaces).
  static const _lightColors = {
    'keyword': Color(0xFF8B3A9E),
    'string': Color(0xFF1B7A3D),
    'number': Color(0xFFC2410C),
    'comment': Color(0xFF6B7280),
    'punctuation': Color(0xFF0E7490),
    'builtin': Color(0xFFC89B3C),
    'plain': Color(0xFF1F2328),
  };

  static Map<String, Color> _paletteFor(Brightness brightness) =>
      brightness == Brightness.dark ? _darkColors : _lightColors;

  static List<TextSpan> highlight(String code, String? language, Brightness brightness) {
    final colors = _paletteFor(brightness);
    final lang = (language ?? '').toLowerCase().trim();
    final keywords = _keywords[lang] ?? _keywords['plain'] ?? [];

    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    int i = 0;

    void flush() {
      if (buffer.isEmpty) return;
      final word = buffer.toString();
      buffer.clear();

      if (keywords.contains(word)) {
        spans.add(TextSpan(text: word, style: TextStyle(color: colors['keyword'])));
      } else if (RegExp(r'^\d+\.?\d*$').hasMatch(word)) {
        spans.add(TextSpan(text: word, style: TextStyle(color: colors['number'])));
      } else if (word.startsWith('#')) {
        spans.add(TextSpan(text: word, style: TextStyle(color: colors['comment'], fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(text: word, style: TextStyle(color: colors['plain'])));
      }
    }

    bool inString = false;
    String? stringQuote;
    bool inSingleLineComment = false;

    while (i < code.length) {
      final ch = code[i];
      final next = i + 1 < code.length ? code[i + 1] : null;

      if (inSingleLineComment) {
        if (ch == '\n') {
          inSingleLineComment = false;
          flush();
          spans.add(TextSpan(text: '\n', style: TextStyle(color: colors['plain'])));
          i++;
          continue;
        }
        buffer.write(ch);
        i++;
        continue;
      }

      if (inString) {
        if (ch == '\\' && next != null) {
          buffer.write(ch);
          buffer.write(next);
          i += 2;
          continue;
        }
        if (ch == stringQuote) {
          inString = false;
          buffer.write(ch);
          final s = buffer.toString();
          buffer.clear();
          spans.add(TextSpan(text: s, style: TextStyle(color: colors['string'])));
          stringQuote = null;
          i++;
          continue;
        }
        buffer.write(ch);
        i++;
        continue;
      }

      if (ch == '"' || ch == "'" || ch == '`') {
        flush();
        inString = true;
        stringQuote = ch;
        buffer.write(ch);
        i++;
        continue;
      }

      if (ch == '/' && next == '/') {
        flush();
        inSingleLineComment = true;
        buffer.write('//');
        i += 2;
        continue;
      }

      if (RegExp(r'[\w_]').hasMatch(ch)) {
        buffer.write(ch);
        i++;
        continue;
      }

      flush();

      if (RegExp(r'[(){}\[\]<>=+\-*/%!&|^~?:;.,]').hasMatch(ch)) {
        spans.add(TextSpan(text: ch, style: TextStyle(color: colors['punctuation'])));
      } else {
        spans.add(TextSpan(text: ch, style: TextStyle(color: colors['plain'])));
      }
      i++;
    }

    flush();
    return spans;
  }
}
