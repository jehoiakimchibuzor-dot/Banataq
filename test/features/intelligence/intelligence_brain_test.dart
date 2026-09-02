import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntelligenceBrain buildBrain({
    LlmProvider? provider,
    IntelligenceEngine? engine,
  }) {
    final e = engine ?? IntelligenceEngine.offline(provider: provider);
    return e.brain;
  }

  test('chat persists the turn to conversation memory', () async {
    final brain = buildBrain();
    final reply = await brain.chat(
      conversationId: 'c1',
      userMessage: 'What is the budget for next term?',
    );

    expect(reply.text, isNotEmpty);
    expect(reply.iterations, 1);
    expect(reply.usage.totalTokens, greaterThan(0));

    final history = await brain.historyStore.messages('c1');
    expect(history, hasLength(2));
    expect(history.first.role, IntelligenceRole.user);
    expect(history.last.role, IntelligenceRole.assistant);
  });

  test('streamChat emits deltas and records history', () async {
    final brain = buildBrain();
    final deltas = <String>[];
    await for (final chunk in brain.streamChat(
      conversationId: 'c1',
      userMessage: 'Write a welcome note',
    )) {
      deltas.add(chunk);
    }
    expect(deltas, isNotEmpty);
    final full = deltas.join();
    expect(full, isNotEmpty);
    expect((await brain.historyStore.messages('c1')).length, 2);
  });

  test('long-term memory is recalled on later turns', () async {
    final brain = buildBrain();
    await brain.remember(
      const LongTermMemory(
        id: 'm1',
        type: MemoryEntryType.rule,
        content: 'approve all orders before Friday',
        importance: 0.9,
      ),
    );

    final reply = await brain.chat(
      conversationId: 'c1',
      userMessage: 'When must orders be approved?',
    );

    expect(reply.memoriesUsed, isNotEmpty);
    expect(reply.memoriesUsed.first.content, contains('before Friday'));
  });

  test('memories with a lower recall weight fall back to important ones', () async {
    final brain = buildBrain();
    await brain.remember(
      const LongTermMemory(
        id: 'critical',
        type: MemoryEntryType.rule,
        content: 'school closes at 4pm daily',
        importance: 1.0,
      ),
    );

    final reply = await brain.chat(
      conversationId: 'c1',
      userMessage: 'zzz unrelated topic about nothing at all',
    );

    // No keyword hit -> importance fallback surfaces the critical rule.
    expect(reply.memoriesUsed, isNotEmpty);
  });

  test('memory extraction happens automatically after a turn', () async {
    final brain = buildBrain();
    await brain.chat(
      conversationId: 'c1',
      userMessage: 'remember that the supplier is Abubakar Traders',
    );

    final memories = await brain.memoryStore.all();
    expect(memories, hasLength(1));
    expect(memories.single.type, MemoryEntryType.fact);
    expect(memories.single.content, contains('Abubakar Traders'));
  });

  test('tool-calling loop executes tools and returns results', () async {
    final engine = IntelligenceEngine.offline(
      provider: MockLlmProvider(),
    );
    engine.toolRunner.register(
      const ToolDefinition(
        name: 'search_workspace',
        description: 'Search the workspace.',
      ),
      (call) async => 'Found 3 results for "${call.arguments['query']}".',
    );

    final reply = await engine.brain.chat(
      conversationId: 'c1',
      userMessage: 'use search_workspace to find the budget documents',
    );

    expect(reply.toolResults, hasLength(1));
    expect(reply.toolResults.single.isError, isFalse);
    expect(reply.toolResults.single.name, 'search_workspace');
    expect(reply.iterations, 2, reason: 'tool round trip then final answer');
  });

  test('failing tools do not loop forever', () async {
    final engine = IntelligenceEngine.offline(
      provider: MockLlmProvider(),
    );
    engine.toolRunner.register(
      const ToolDefinition(name: 'boom', description: ''),
      (_) async => throw StateError('nope'),
    );

    final reply = await engine.brain.chat(
      conversationId: 'c1',
      userMessage: 'call boom and see what happens',
    );

    expect(reply.toolResults.single.isError, isTrue);
    expect(reply.iterations, lessThanOrEqualTo(2));
    expect(reply.text, isNotEmpty);
  });

  test('streaming path also runs tools', () async {
    final engine = IntelligenceEngine.offline(
      provider: MockLlmProvider(),
    );
    engine.toolRunner.register(
      const ToolDefinition(name: 'list_files', description: ''),
      (call) async => 'a.pdf\nb.xlsx',
    );

    final chunks = <String>[];
    await for (final chunk in engine.brain.streamChat(
      conversationId: 'c1',
      userMessage: 'please list_files for me',
    )) {
      chunks.add(chunk);
    }
    expect(chunks, isNotEmpty);
    expect((await engine.brain.historyStore.messages('c1')).length, 2);
  });

  test('two conversations stay isolated', () async {
    final brain = buildBrain();
    await brain.chat(conversationId: 'a', userMessage: 'hello from a');
    await brain.chat(conversationId: 'b', userMessage: 'hello from b');

    final a = await brain.historyStore.messages('a');
    final b = await brain.historyStore.messages('b');
    expect(a.last.content, isNot(b.last.content));
    expect(a, hasLength(2));
    expect(b, hasLength(2));
  });
}
