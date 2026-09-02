import 'dart:convert';

import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('brain runs the full Ollama tool loop offline', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = (body['messages'] as List).cast<Map>();
      final hasToolResult =
          messages.any((m) => m['role'] == 'tool');

      if (hasToolResult) {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'index': 0,
                'message': {
                  'role': 'assistant',
                  'content': 'The supplier quote is NGN 450,000.',
                },
                'finish_reason': 'stop',
              },
            ],
            'usage': {'prompt_tokens': 5, 'completion_tokens': 8},
          }),
          200,
        );
      }

      return http.Response(
        jsonEncode({
          'choices': [
            {
              'index': 0,
              'message': {
                'role': 'assistant',
                'content': null,
                'tool_calls': [
                  {
                    'id': 'call_1',
                    'type': 'function',
                    'function': {
                      'name': 'search_workspace',
                      'arguments': '{"query":"suppliers"}',
                    },
                  },
                ],
              },
              'finish_reason': 'tool_calls',
            },
          ],
          'usage': {'prompt_tokens': 5, 'completion_tokens': 5},
        }),
        200,
      );
    });

    final engine = await WorkspaceBrainFactory.buildWithOllama(
      repository: MockWorkspaceRepository(),
      client: client,
    );

    final reply = await engine.brain.chat(
      conversationId: 'c1',
      userMessage: 'suppliers quote',
    );

    expect(calls, 2);
    expect(reply.toolResults, hasLength(1));
    expect(reply.toolResults.single.isError, isFalse);
    expect(reply.text, 'The supplier quote is NGN 450,000.');
    expect(reply.sources, isNotEmpty);
  });
}
