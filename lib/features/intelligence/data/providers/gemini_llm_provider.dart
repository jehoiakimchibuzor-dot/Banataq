import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/chat_usage.dart';
import '../../domain/models/intelligence_message.dart';
import '../../domain/models/llm_request.dart';
import '../../domain/models/llm_response.dart';
import '../../domain/models/llm_stream_event.dart';
import '../../domain/models/tool_call.dart';
import '../../domain/providers/llm_provider.dart';

/// Gemini adapter (gemini-2.0-flash), including function declarations and
/// SSE streaming. Network-free by design in tests.
class GeminiLlmProvider implements LlmProvider {
  GeminiLlmProvider({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  String get name => 'Gemini';

  @override
  Set<LlmCapability> get capabilities => {
        LlmCapability.streaming,
        LlmCapability.toolCalls,
      };

  @override
  int get contextWindow => 1000000;

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent?key=$apiKey',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_buildBody(request)),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${response.statusCode} ${response.body}',
      );
    }
    return _parseResponse(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Stream<LlmStreamEvent> stream(LlmRequest request) async* {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:streamGenerateContent?alt=sse&key=$apiKey',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_buildBody(request)),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Gemini stream error: ${response.statusCode} ${response.body}',
      );
    }
    final lines = utf8.decode(response.bodyBytes).split('\n');
    for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      try {
        final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
        final parts = (json['candidates'] as List?)?.firstOrNull?['content']
            ?['parts'] as List?;
        if (parts == null) continue;
        for (final part in parts) {
          final map = part as Map<String, dynamic>;
          final text = map['text'] as String?;
          if (text != null && text.isNotEmpty) {
            yield LlmTextDelta(text);
          }
          final call = map['functionCall'] as Map<String, dynamic>?;
          if (call != null) {
            yield LlmToolCallEvent(
              ToolCall(
                id: call['name'] as String? ?? 'gemini-call',
                name: call['name'] as String? ?? '',
                arguments: (call['args'] as Map<String, dynamic>?) ?? {},
              ),
            );
          }
        }
        if ((json['candidates'] as List?)?.firstOrNull?['finishReason'] !=
            null) {
          yield LlmDoneEvent(ChatUsage.empty);
        }
      } catch (_) {
        // Skip malformed chunks.
      }
    }
    yield LlmDoneEvent(ChatUsage.empty);
  }

  Map<String, dynamic> _buildBody(LlmRequest request) {
    final contents = <Map<String, dynamic>>[];
    for (final message in request.messages) {
      switch (message.role) {
        case IntelligenceRole.user:
          contents.add({
            'role': 'user',
            'parts': [
              {'text': message.content},
            ],
          });
        case IntelligenceRole.assistant:
          contents.add({
            'role': 'model',
            'parts': [
              {'text': message.content},
            ],
          });
        case IntelligenceRole.tool:
          contents.add({
            'role': 'user',
            'parts': [
              {'text': 'Tool result: ${message.content}'},
            ],
          });
        case IntelligenceRole.system:
          contents.add({
            'role': 'user',
            'parts': [
              {'text': message.content},
            ],
          });
      }
    }
    return {
      if (request.systemPrompt != null)
        'systemInstruction': {
          'parts': [
            {'text': request.systemPrompt},
          ],
        },
      'contents': contents,
      'generationConfig': {
        'temperature': request.temperature,
        'maxOutputTokens': request.maxTokens,
      },
      if (request.tools.isNotEmpty)
        'tools': [
          {
            'functionDeclarations': [
              for (final tool in request.tools)
                {
                  'name': tool.name,
                  'description': tool.description,
                  'parameters': tool.parameters,
                },
            ],
          },
        ],
    };
  }

  LlmResponse _parseResponse(Map<String, dynamic> data) {
    final candidate = (data['candidates'] as List?)?.firstOrNull
        as Map<String, dynamic>?;
    final parts = candidate?['content']?['parts'] as List? ?? const [];
    final buffer = StringBuffer();
    final toolCalls = <ToolCall>[];
    for (final part in parts) {
      final map = part as Map<String, dynamic>;
      final text = map['text'] as String?;
      if (text != null) buffer.write(text);
      final call = map['functionCall'] as Map<String, dynamic>?;
      if (call != null) {
        toolCalls.add(
          ToolCall(
            id: call['name'] as String? ?? 'gemini-call',
            name: call['name'] as String? ?? '',
            arguments: (call['args'] as Map<String, dynamic>?) ?? {},
          ),
        );
      }
    }
    return LlmResponse(content: buffer.toString(), toolCalls: toolCalls);
  }
}
