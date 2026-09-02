import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/ollama_config.dart';
import '../../domain/models/chat_usage.dart';
import '../../domain/models/intelligence_message.dart';
import '../../domain/models/llm_request.dart';
import '../../domain/models/llm_response.dart';
import '../../domain/models/llm_stream_event.dart';
import '../../domain/models/tool_call.dart';
import '../../domain/providers/llm_provider.dart';

/// Raised when Ollama returns a non-2xx status or an unparseable payload.
class LlmProviderException implements Exception {
  const LlmProviderException(this.message);

  final String message;

  @override
  String toString() => 'LlmProviderException: $message';
}

/// Local Ollama adapter speaking the OpenAI-compatible endpoint
/// (`POST {baseUrl}/chat/completions`), targeting the pulled qwen2.5:3b model.
///
/// Translates the neutral [LlmRequest] into the OpenAI wire format — including
/// function/tool calling and SSE streaming — so it drops straight into the
/// existing [LlmProvider] seam. Network-free by design in tests (inject a
/// `MockClient`).
class OllamaLlmProvider implements LlmProvider {
  OllamaLlmProvider({
    String? baseUrl,
    String? model,
    http.Client? client,
    this.timeout = const Duration(minutes: 10),
  })  : baseUrl = baseUrl ?? OllamaConfig.defaultBaseUrl,
        model = model ?? OllamaConfig.model,
        _client = client ?? http.Client();

  final String baseUrl;
  final String model;

  /// Upper bound for one request; generation is slow on CPU (a few tok/s).
  final Duration timeout;

  final http.Client _client;

  @override
  String get name => 'Ollama';

  @override
  Set<LlmCapability> get capabilities => {
        LlmCapability.streaming,
        LlmCapability.toolCalls,
      };

  /// qwen2.5:3b exposes a 32K context window.
  @override
  int get contextWindow => 32768;

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    final response = await _post(request, stream: false);
    if (response.statusCode != 200) {
      throw LlmProviderException(
        'Ollama API error: ${response.statusCode} ${response.body}',
      );
    }
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw LlmProviderException('Malformed Ollama response: $e');
    }
    return _parseCompletion(data);
  }

  @override
  Stream<LlmStreamEvent> stream(LlmRequest request) async* {
    final response = await _post(request, stream: true);
    if (response.statusCode != 200) {
      throw LlmProviderException(
        'Ollama stream error: ${response.statusCode} ${response.body}',
      );
    }

    final toolBuffer = <int, Map<String, dynamic>>{};
    var doneYielded = false;
    for (final line in utf8.decode(response.bodyBytes).split('\n')) {
      if (!line.startsWith('data: ')) continue;
      final payload = line.substring(6).trim();
      if (payload == '[DONE]') break;
      final Map<String, dynamic> json;
      try {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } catch (_) {
        continue; // Skip malformed chunks; keep streaming.
      }
      final choice =
          (json['choices'] as List?)?.firstOrNull as Map<String, dynamic>?;
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
          buffer['name'] = (function['name'] as String?) ??
              (buffer['name'] as String?) ??
              '';
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
        yield LlmDoneEvent(
          _usageFromJson(json['usage'] as Map<String, dynamic>?),
        );
        doneYielded = true;
      }
    }
    if (!doneYielded) yield LlmDoneEvent(ChatUsage.empty);
  }

  Future<http.Response> _post(
    LlmRequest request, {
    required bool stream,
  }) {
    return _client
        .post(
          Uri.parse('$baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            if (stream) 'Accept': 'text/event-stream',
          },
          body: jsonEncode(_buildBody(request, stream: stream)),
        )
        .timeout(timeout);
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
    final choice =
        (data['choices'] as List?)?.firstOrNull as Map<String, dynamic>?;
    final message =
        choice?['message'] as Map<String, dynamic>? ?? const {};
    final rawCalls = message['tool_calls'] as List? ?? const [];
    final toolCalls = [
      for (final raw in rawCalls)
        _toolCallFromJson(raw as Map<String, dynamic>),
    ].whereType<ToolCall>().toList();
    return LlmResponse(
      content: message['content'] as String? ?? '',
      toolCalls: toolCalls,
      usage: _usageFromJson(data['usage'] as Map<String, dynamic>?),
    );
  }

  ToolCall? _toolCallFromJson(Map<String, dynamic> item) {
    final function = item['function'] as Map<String, dynamic>? ?? const {};
    return _toolCallFromBuffer({
      'id': item['id'],
      'name': function['name'],
      'arguments': function['arguments'],
    });
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
