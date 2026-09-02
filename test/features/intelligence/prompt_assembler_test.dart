import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assemble includes persona, memories, documents and tools', () {
    final assembler = DefaultPromptAssembler();
    const memory = LongTermMemory(
      id: 'm1',
      type: MemoryEntryType.rule,
      content: 'approve orders above 50k',
      importance: 0.8,
    );
    const chunk = RagChunk(
      id: 'c1',
      documentId: 'doc1',
      title: 'Budget plan',
      text: 'The school budget is capped at 200k.',
      chunkIndex: 0,
    );
    const tool = ToolDefinition(
      name: 'search_workspace',
      description: 'Search the workspace.',
    );

    final assembled = assembler.assemble(
      AssemblerInput(
        userMessage: const IntelligenceMessage(
          role: IntelligenceRole.user,
          content: 'What is the budget?',
        ),
        persona: 'school administrator',
        systemInstructions: 'Answer in Hausa or English.',
        memories: const [memory],
        documents: const [chunk],
        tools: const [tool],
      ),
    );

    expect(assembled.systemPrompt, contains('school administrator'));
    expect(assembled.systemPrompt, contains('approve orders above 50k'));
    expect(assembled.systemPrompt, contains('Budget plan'));
    expect(assembled.systemPrompt, contains('search_workspace'));
    expect(assembled.systemPrompt, contains('Answer in Hausa or English.'));
    expect(assembled.memoriesUsed, hasLength(1));
    expect(assembled.documentsUsed, hasLength(1));
    // The current user message is always present.
    expect(assembled.messages.last.content, 'What is the budget?');
  });

  test('empty optional blocks are omitted cleanly', () {
    final assembler = DefaultPromptAssembler();
    final assembled = assembler.assemble(
      AssemblerInput(
        userMessage: const IntelligenceMessage(
          role: IntelligenceRole.user,
          content: 'hello',
        ),
      ),
    );
    expect(assembled.systemPrompt, contains('AI operating system'));
    expect(assembled.systemPrompt.contains('## Long-term memory'), isFalse);
    expect(assembled.systemPrompt.contains('## Retrieved knowledge'), isFalse);
    expect(assembled.messages, hasLength(1));
    expect(assembled.estimatedTokens, greaterThan(0));
  });

  test('history compression reports dropped messages', () {
    final assembler = DefaultPromptAssembler();
    final longHistory = [
      for (var i = 0; i < 30; i++)
        IntelligenceMessage(
          role: IntelligenceRole.user,
          content: 'message number $i with padding words to inflate the count',
        ),
    ];
    final assembled = assembler.assemble(
      AssemblerInput(
        userMessage: const IntelligenceMessage(
          role: IntelligenceRole.user,
          content: 'current question',
        ),
        history: longHistory,
        tokenBudget: 80,
      ),
    );
    expect(assembled.droppedHistoryCount, greaterThan(0));
    expect(assembled.messages.length, lessThan(31));
    expect(assembled.systemPrompt, contains('Summary of earlier context'));
  });

  test('system prompt is not counted inside the message window', () {
    final assembler = DefaultPromptAssembler();
    final assembled = assembler.assemble(
      AssemblerInput(
        userMessage: const IntelligenceMessage(
          role: IntelligenceRole.user,
          content: 'hi',
        ),
      ),
    );
    expect(
      assembled.messages.every(
        (m) => m.role != IntelligenceRole.system,
      ),
      isTrue,
    );
  });
}
