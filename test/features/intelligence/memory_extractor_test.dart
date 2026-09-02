import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = SimpleMemoryExtractor();

  test('extracts "remember that ..." as a fact', () {
    final memories = extractor.extract('remember that Abubakar Traders gives us bulk discounts');
    expect(memories, hasLength(1));
    expect(memories.single.type, MemoryEntryType.fact);
    expect(memories.single.content, contains('Abubakar Traders'));
  });

  test('extracts "I prefer ..." as a preference', () {
    final memories = extractor.extract('I prefer weekly meetings on Mondays');
    expect(memories.single.type, MemoryEntryType.preference);
    expect(memories.single.importance, 0.6);
  });

  test('extracts "always ..." as a rule with higher importance', () {
    final memories = extractor.extract('always approve orders before Friday');
    expect(memories.single.type, MemoryEntryType.rule);
    expect(memories.single.importance, 0.8);
  });

  test('produces stable, deterministic ids', () {
    final a = extractor.extract('remember that the venue is the town hall');
    final b = extractor.extract('remember that the venue is the town hall');
    expect(a.single.id, b.single.id);
  });

  test('plain questions yield no memories', () {
    expect(extractor.extract('What is the budget for next term?'), isEmpty);
    expect(extractor.extract(''), isEmpty);
  });
}
