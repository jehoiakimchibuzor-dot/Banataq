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

/// OpenAI Chat Completions adapter (gpt-4o family).
///
/// Translates the neutral [LlmRequest] into the OpenAI wire format, including
/// function/tool calling and SSE streaming. Network-free by design in tests.
class OpenAiLlmProvider implements LlmProvider {
  OpenAiLlmProvider({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String baseUrl;
  final String model;
  final http.Client _client;

  @override
  String get name => 'OpenAI';

  @override
  Set<LlmCapability> get capabilities => {
        LlmCapability.streaming,
        LlmCapability.toolCalls,
      };

  @override
  int get contextWindow => 128000;

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    final body = _buildBody(request, stream: false);
    final response = await _client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API error: ${response.statusCode} ${response.body}',
      );
    }
    return _parseCompletion(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Stream<LlmStreamEvent> stream(LlmRequest request) async* {
    final response = await _client.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {..._headers, 'Accept': 'text/event-stream'},
      body: jsonEncode(_buildBody(request, stream: true)),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI stream error: ${response.statusCode} ${response.body}',
      );
    }

    final toolBuffer = <int, Map<String, dynamic>>{};
    final lines = utf8.decode(response.bodyBytes).split('\n');
    for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6).trim();
      if (payload == '[DONE]') break;
      try {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        final choice = (json['choices'] as List?)?.firstOrNull
            as Map<String, dynamic>?;
        if (choice == null) continue;
        final delta = choice['delta'] as Map<String, dynamic>? ?? const {};
        final text = delta['content'] as String?;
        if (text != null && text.isNotEmpty) {
          yield LlmTextDelta(text);
        }
        final toolCalls = delta['tool_calls'] as List?;
        if (toolCalls != null) {
          for (final raw in toolCalls) {
            final item = raw as Map<String, dynamic>;
            final index = item['index'] as int? ?? 0;
            final buffer = toolBuffer.putIfAbsent(index, () => {});
            final function = item['function'] as Map<String, dynamic>? ?? const {};
            buffer['id'] = item['id'] as String? ?? buffer['id'];
            buffer['name'] =
                (function['name'] as String?) ?? (buffer['name'] as String?) ?? '';
            final args = function['arguments'] as String? ?? '';
            buffer['arguments'] = (buffer['arguments'] as String? ?? '') + args;
          }
        }
        final finish = choice['finish_reason'] as String?;
        if (finish == 'tool_calls') {
          for (final entry in toolBuffer.entries) {
            final call = _toolCallFromBuffer(entry.value);
            if (call != null) yield LlmToolCallEvent(call);
          }
          toolBuffer.clear();
        }
        if (finish == 'stop' || finish == 'length') {
          final usage = json['usage'] as Map<String, dynamic>?;
          yield LlmDoneEvent(_usageFromJson(usage));
        }
      } catch (_) {
        // Skip malformed chunks; keep streaming.
      }
    }
    yield LlmDoneEvent(ChatUsage.empty);
  }

  Map<String, dynamic> _buildBody(LlmRequest request, {required bool stream}) {
    final messages = <Map<String, dynamic>>[
      if (request.systemPrompt != null)
        {'role': 'system', 'content': request.systemPrompt},
      for (final message in request.messages) _messageToJson(message),
    ];
    return {
      'model': model,
      'messages': messages,
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
      'stream': stream,
      if (request.tools.isNotEmpty)
        'tools': [
          for (final tool in request.tools)
            {
              'type': 'function',
              'function': {
                'name': tool.name,
                'description': tool.description,
                'parameters': tool.parameters,
              },
            },
        ],
    };
  }

  LlmResponse _parseCompletion(Map<String, dynamic> data) {
    final choice = (data['choices'] as List?)?.firstOrNull
        as Map<String, dynamic>?;
    final message =
        choice?['message'] as Map<String, dynamic>? ?? const {};
    final rawCalls = message['tool_calls'] as List? ?? const [];
    final toolCalls = <ToolCall>[
      for (final raw in rawCalls)
        _toolCallFromBuffer(raw as Map<String, dynamic>)!,
    ]..removeWhere((c) => c.name.isEmpty);
    return LlmResponse(
      content: message['content'] as String? ?? '',
      toolCalls: toolCalls,
      usage: _usageFromJson(data['usage'] as Map<String, dynamic>?),
    );
  }

  ToolCall? _toolCallFromBuffer(Map<String, dynamic> buffer) {
    final id = buffer['id'] as String?;
    final name = buffer['name'] as String?;
    final argsRaw = buffer['arguments'] as String?;
    if (name == null || name.isEmpty) return null;
    Map<String, dynamic> args = {};
    if (argsRaw != null && argsRaw.isNotEmpty) {
      try {
        args = (jsonDecode(argsRaw) as Map<String, dynamic>);
      } catch (_) {
        args = {'_raw': argsRaw};
      }
    }
    return ToolCall(id: id ?? name, name: name, arguments: args);
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  static ChatUsage _usageFromJson(Map<String, dynamic>? json) {
    if (json == null) return ChatUsage.empty;
    return ChatUsage(
      promptTokens: json['prompt_tokens'] as int? ?? 0,
      completionTokens: json['completion_tokens'] as int? ?? 0,
    );
  }

  static Map<String, dynamic> _messageToJson(IntelligenceMessage message) {
    switch (message.role) {
      case IntelligenceRole.user:
        return {'role': 'user', 'content': message.content};
      case IntelligenceRole.assistant:
        return {
          'role': 'assistant',
          'content': message.content,
          if (message.name != null) 'name': message.name,
        };
      case IntelligenceRole.system:
        return {'role': 'system', 'content': message.content};
      case IntelligenceRole.tool:
        return {
          'role': 'tool',
          'content': message.content,
          'tool_call_id': message.toolCallId ?? '',
        };
    }
  }
}
