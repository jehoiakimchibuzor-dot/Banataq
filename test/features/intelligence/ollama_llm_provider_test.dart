import 'dart:convert';

import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Helper building an OpenAI-compatible non-stream completion payload.
Map<String, dynamic> completionJson({
  String content = '',
  List<Map<String, dynamic>> toolCalls = const [],
}) {
  return {
    'id': 'chatcmpl-test',
    'model': 'qwen3:1.7b',
    'choices': [
      {
        'index': 0,
        'message': {
          'role': 'assistant',
          'content': content,
          if (toolCalls.isNotEmpty) 'tool_calls': toolCalls,
        },
        'finish_reason': toolCalls.isEmpty ? 'stop' : 'tool_calls',
      },
    ],
    'usage': {'prompt_tokens': 10, 'completion_tokens': 5},
  };
}

void main() {
  LlmRequest request({
    String user = 'What is the budget?',
    List<ToolDefinition> tools = const [],
    List<IntelligenceMessage>? messages,
  }) {
    return LlmRequest(
      systemPrompt: 'You are Banataq.',
      messages: messages ??
          [IntelligenceMessage(role: IntelligenceRole.user, content: user)],
      tools: tools,
    );
  }

  const baseUrl = 'http://localhost:11434/v1';

  group('OllamaLlmProvider.complete', () {
    test('parses content and usage from the OpenAI-compatible endpoint',
        () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/chat/completions');
        expect(request.headers, isNot(contains('Authorization')));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'qwen3:1.7b');
        expect(body['stream'], isFalse);
        return http.Response(
          jsonEncode(completionJson(content: 'Budget is NGN 450,000.')),
          200,
        );
      });

      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      final response = await provider.complete(request());

      expect(response.content, 'Budget is NGN 450,000.');
      expect(response.hasToolCalls, isFalse);
      expect(response.usage.totalTokens, 15);
    });

    test('parses a tool call request', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(completionJson(toolCalls: [
            {
              'id': 'call_1',
              'type': 'function',
              'function': {
                'name': 'search_workspace',
                'arguments': '{"query":"suppliers"}',
              },
            },
          ])),
          200,
        );
      });

      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      final response = await provider.complete(request());

      expect(response.hasToolCalls, isTrue);
      expect(response.toolCalls.single.name, 'search_workspace');
      expect(response.toolCalls.single.arguments, {'query': 'suppliers'});
    });

    test('serialises a tool result message for the second completion', () async {
      late Map<String, dynamic> capturedBody;
      final client = MockClient((request) async {
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(completionJson(content: 'Found supplier quote.')),
          200,
        );
      });

      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      await provider.complete(
        request(messages: [
          IntelligenceMessage(
            role: IntelligenceRole.user,
            content: 'search_workspace suppliers',
          ),
          IntelligenceMessage(
            role: IntelligenceRole.assistant,
            content: '',
            name: 'search_workspace',
          ),
          IntelligenceMessage(
            role: IntelligenceRole.tool,
            content: 'Supplier quote: NGN 450,000',
            toolCallId: 'call_1',
          ),
        ]),
      );

      final roles =
          (capturedBody['messages'] as List).map((m) => (m as Map)['role']);
      expect(roles, contains('tool'));
      final toolMsg = (capturedBody['messages'] as List)
          .cast<Map>()
          .firstWhere((m) => m['role'] == 'tool');
      expect(toolMsg['tool_call_id'], 'call_1');
    });

    test('throws a typed exception on a non-2xx response', () async {
      final client =
          MockClient((_) async => http.Response('model not found', 404));
      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      expect(
        () => provider.complete(request()),
        throwsA(isA<LlmProviderException>()),
      );
    });

    test('throws a typed exception on a malformed body', () async {
      final client =
          MockClient((_) async => http.Response('not-json{{{', 200));
      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      expect(
        () => provider.complete(request()),
        throwsA(isA<LlmProviderException>()),
      );
    });
  });

  group('OllamaLlmProvider.stream', () {
    test('emits text deltas then a done event', () async {
      final client = MockClient((_) async {
        return http.Response(
          [
            'data: {"choices":[{"delta":{"content":"Hello "}}]}',
            '',
            'data: {"choices":[{"delta":{"content":"world"}}],"usage":{"prompt_tokens":10,"completion_tokens":5}}',
            '',
            'data: [DONE]',
            '',
          ].join('\n'),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      final events = await provider.stream(request()).toList();

      final deltas = events.whereType<LlmTextDelta>();
      expect(deltas.map((d) => d.text).join(), 'Hello world');
      expect(events.last, isA<LlmDoneEvent>());
    });

    test('buffers split tool-call arguments across chunks', () async {
      final client = MockClient((_) async {
        return http.Response(
          [
            'data: {"choices":[{"delta":{"role":"assistant","tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"search_workspace","arguments":""}}]}}]}',
            '',
            'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"{\\"query\\":"}}]}}]}',
            '',
            'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":"\\"suppliers\\"}"}}]},"finish_reason":"tool_calls"}]}',
            '',
            'data: [DONE]',
            '',
          ].join('\n'),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      final events = await provider.stream(request()).toList();

      final call =
          events.whereType<LlmToolCallEvent>().single.call;
      expect(call.name, 'search_workspace');
      expect(call.arguments, {'query': 'suppliers'});
      expect(events.last, isA<LlmDoneEvent>());
    });

    test('skips malformed chunks without crashing', () async {
      final client = MockClient((_) async {
        return http.Response(
          [
            'data: not-json-{{{',
            '',
            'data: {"choices":[{"delta":{"content":"still works"}}]}',
            '',
            'data: [DONE]',
            '',
          ].join('\n'),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });

      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      final events = await provider.stream(request()).toList();

      final deltas = events.whereType<LlmTextDelta>();
      expect(deltas.map((d) => d.text).join(), 'still works');
      expect(events.last, isA<LlmDoneEvent>());
    });

    test('throws a typed exception on a non-2xx stream', () async {
      final client =
          MockClient((_) async => http.Response('down', 503));
      final provider = OllamaLlmProvider(baseUrl: baseUrl, client: client);
      expect(
        () => provider.stream(request()).toList(),
        throwsA(isA<LlmProviderException>()),
      );
    });
  });

  group('capabilities', () {
    test('advertises streaming and tool calling', () {
      final provider = OllamaLlmProvider(baseUrl: baseUrl);
      expect(provider.capabilities, contains(LlmCapability.streaming));
      expect(provider.capabilities, contains(LlmCapability.toolCalls));
    });
  });
}
