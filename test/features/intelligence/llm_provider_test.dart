import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LlmRequest request({
    String user = 'What is the budget?',
    List<ToolDefinition> tools = const [],
  }) {
    return LlmRequest(
      systemPrompt: 'You are Banataq.',
      messages: [
        IntelligenceMessage(role: IntelligenceRole.user, content: user),
      ],
      tools: tools,
    );
  }

  group('MockLlmProvider', () {
    test('complete returns a deterministic answer', () async {
      final provider = MockLlmProvider(seed: 'test');
      final response = await provider.complete(request());
      expect(response.content, contains('deterministic mock answer'));
      expect(response.content, contains('What is the budget?'));
      expect(response.hasToolCalls, isFalse);
      expect(response.usage.totalTokens, greaterThan(0));
    });

    test('requests a tool when the tool name appears in the message', () async {
      final provider = MockLlmProvider();
      final response = await provider.complete(
        request(
          user: 'please search_workspace for the budget',
          tools: const [
            ToolDefinition(name: 'search_workspace', description: 'Search'),
          ],
        ),
      );
      expect(response.hasToolCalls, isTrue);
      expect(response.toolCalls.single.name, 'search_workspace');
      expect(response.toolCalls.single.arguments['query'], contains('budget'));
    });

    test('ignores tools not mentioned by the user', () async {
      final provider = MockLlmProvider();
      final response = await provider.complete(
        request(tools: const [
          ToolDefinition(name: 'search_workspace', description: 'Search'),
        ]),
      );
      expect(response.hasToolCalls, isFalse);
    });

    test('stream emits deltas then a done event', () async {
      final provider = MockLlmProvider();
      final events = await provider.stream(request()).toList();
      final deltas = events.whereType<LlmTextDelta>();
      expect(deltas, isNotEmpty);
      expect(events.last, isA<LlmDoneEvent>());
      final fullText = deltas.map((d) => d.text).join();
      expect(fullText, contains('deterministic mock answer'));
    });

    test('stream surfaces tool calls', () async {
      final provider = MockLlmProvider();
      final events = await provider.stream(
        request(
          user: 'call list_files now',
          tools: const [
            ToolDefinition(name: 'list_files', description: 'List'),
          ],
        ),
      ).toList();
      expect(
        events.whereType<LlmToolCallEvent>().single.call.name,
        'list_files',
      );
    });
  });

  group('LocalLlmProvider (offline)', () {
    test('answers common intents offline', () async {
      final provider = LocalLlmProvider();
      final summarize = await provider.complete(request(user: 'summarize my notes'));
      expect(summarize.content, contains('bullet points'));

      final business = await provider.complete(request(user: 'help me with a business description'));
      expect(business.content, contains('business description'));
    });

    test('declares no tool-calling capability', () {
      final provider = LocalLlmProvider();
      expect(provider.capabilities, isNot(contains(LlmCapability.toolCalls)));
      expect(provider.capabilities, contains(LlmCapability.streaming));
    });

    test('streams word-by-word', () async {
      final provider = LocalLlmProvider();
      final deltas = <LlmTextDelta>[];
      await for (final event
          in provider.stream(request(user: 'summarize this'))) {
        if (event is LlmTextDelta) deltas.add(event);
      }
      expect(deltas, isNotEmpty);
      expect(deltas.map((d) => d.text).join(), contains('bullet points'));
    });
  });
}
