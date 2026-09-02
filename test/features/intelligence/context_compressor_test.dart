import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tokenizer = SimpleTokenizer();
  final compressor = DefaultContextCompressor(tokenizer: tokenizer);

  List<IntelligenceMessage> messages(int count) => [
        const IntelligenceMessage(
          role: IntelligenceRole.system,
          content: 'System instructions.',
        ),
        for (var i = 0; i < count; i++)
          IntelligenceMessage(
            role: IntelligenceRole.user,
            content: 'user message number $i with some padding words',
          ),
      ];

  test('keeps everything within a generous budget', () {
    final result = compressor.compress(
      messages: messages(3),
      budgetTokens: 10000,
    );
    expect(result.messages, hasLength(4));
    expect(result.droppedCount, 0);
  });

  test('drops oldest non-system messages when over budget', () {
    final result = compressor.compress(
      messages: messages(30),
      budgetTokens: 40,
    );
    expect(result.droppedCount, greaterThan(0));
    // The system message is always retained.
    expect(
      result.messages.first.role,
      IntelligenceRole.system,
    );
    // Retained history is strictly the newest tail.
    expect(result.messages.length, lessThan(31));
    // A summary of what was dropped is produced.
    expect(result.summary, isNotNull);
  });

  test('respects a running summary budget', () {
    final result = compressor.compress(
      messages: messages(50),
      budgetTokens: 50,
      runningSummary: 'Earlier we discussed the annual budget allocation.',
    );
    expect(result.droppedCount, greaterThan(0));
    expect(result.summary, contains('annual budget'));
  });

  test('empty input produces an empty result', () {
    final result = compressor.compress(messages: const [], budgetTokens: 100);
    expect(result.messages, isEmpty);
    expect(result.estimatedTokens, 0);
  });

  test('zero budget drops everything', () {
    final result = compressor.compress(messages: messages(2), budgetTokens: 0);
    expect(result.messages, isEmpty);
    expect(result.droppedCount, 3);
  });
}
