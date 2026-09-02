import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tokenizer = SimpleTokenizer();

  test('counts tokens proportionally to length', () {
    expect(tokenizer.countTokens(''), 0);
    expect(tokenizer.countTokens('hello world'), greaterThan(0));
    expect(
      tokenizer.countTokens('a long sentence with several words in it'),
      greaterThan(tokenizer.countTokens('short')),
    );
  });

  test('is deterministic', () {
    const text = 'The quick brown fox jumps over the lazy dog.';
    expect(tokenizer.countTokens(text), tokenizer.countTokens(text));
  });

  test('always returns at least 1 for non-empty text', () {
    expect(tokenizer.countTokens('a'), 1);
  });
}
