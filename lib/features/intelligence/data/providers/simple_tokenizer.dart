import 'dart:math' as math;

import '../../domain/providers/tokenizer.dart';

/// Heuristic offline token counter: words + characters/7, never below 1.
class SimpleTokenizer implements Tokenizer {
  const SimpleTokenizer();

  static final _wordPattern = RegExp(r'\s+');

  @override
  int countTokens(String text) {
    if (text.isEmpty) return 0;
    final words = text.split(_wordPattern).where((w) => w.isNotEmpty).length;
    final estimate = words + (text.length / 7).round();
    return math.max(1, estimate);
  }
}
