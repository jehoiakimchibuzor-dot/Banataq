import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// Shared client for OpenAI-compatible chat APIs (OpenAI, Groq, OpenRouter).
class OpenAIProvider implements AiProvider {
  final String apiKey;
  final String model;
  final String baseUrl;

  @override
  final String name;

  final Map<String, String> extraHeaders;

  OpenAIProvider(
    this.apiKey, {
    this.model = 'gpt-4o-mini',
    this.baseUrl = 'https://api.openai.com/v1',
    this.name = 'OpenAI',
    this.extraHeaders = const {},
  });

  String _systemPrompt(String? persona, String? displayName) {
    final namePart = displayName != null && displayName.trim().isNotEmpty
        ? 'The user\'s name is $displayName. Always greet them warmly by name at the very start (e.g. "Hi $displayName,") before answering. Remember this name for the whole conversation.'
        : 'Greet the user warmly if you know their name.';
    if (persona != null) {
      return 'You are Banataq, an AI assistant helping a $persona user. $namePart Respond concisely and practically for the Nigerian/African context.';
    }
    return 'You are Banataq, a helpful AI assistant. $namePart Respond concisely and practically.';
  }

  List<Map<String, String>> _buildMessages(
      String prompt, String? persona, String? displayName, List<Map<String, String>>? history) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt(persona, displayName)},
    ];
    if (history != null) {
      for (final msg in history) {
        messages.add(msg);
      }
    }
    messages.add({'role': 'user', 'content': prompt});
    return messages;
  }

  /// Some hosted models (e.g. Qwen on Groq) inline a `<think>` reasoning block
  /// in the message content. Strip it so users only see the actual answer.
  static String stripThinking(String text) {
    final cleaned = StringBuffer();
    var inside = false;
    for (var i = 0; i < text.length;) {
      if (!inside && text.startsWith('<think>', i)) {
        inside = true;
        i += 7;
        continue;
      }
      if (inside && text.startsWith('</think>', i)) {
        inside = false;
        i += 8;
        continue;
      }
      if (!inside) cleaned.write(text[i]);
      i++;
    }
    var out = cleaned.toString();
    if (out.trim().isEmpty && text.isNotEmpty) out = text;
    return out.trimLeft();
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        ...extraHeaders,
      };

  @override
  Future<String> generateResponse(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async {
    final messages = _buildMessages(prompt, persona, displayName, history);

    final res = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: _headers(),
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': 2000,
        'temperature': 0.7,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(_friendlyError(res.statusCode, res.body));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    try {
      return stripThinking(data['choices'][0]['message']['content'] as String);
    } catch (_) {
      throw Exception('Unexpected $name response format');
    }
  }

  @override
  Stream<String> generateResponseStream(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async* {
    final messages = _buildMessages(prompt, persona, displayName, history);

    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.headers.addAll(_headers());
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'max_tokens': 2000,
      'temperature': 0.7,
      'stream': true,
    });

    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception(_friendlyError(response.statusCode, body));
    }

    var skippingThink = false;
    var pending = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      pending += chunk;
      // SSE events are newline-delimited; hold back a trailing partial line.
      final lines = pending.split('\n');
      pending = lines.removeLast();
      for (final line in lines) {
        if (line.startsWith('data: ') && line != 'data: [DONE]') {
          try {
            final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            final delta = json['choices']?[0]?['delta'] as Map<String, dynamic>?;
            var content = delta?['content'] as String?;
            if (content == null || content.isEmpty) continue;
            // Filter <think> blocks chunk-by-chunk.
            if (skippingThink) {
              final end = content.indexOf('</think>');
              if (end == -1) continue;
              content = content.substring(end + 8);
              skippingThink = false;
            }
            final start = content.indexOf('<think>');
            if (start != -1) {
              final before = content.substring(0, start);
              final restAfterStart = content.substring(start + 7);
              final endInRest = restAfterStart.indexOf('</think>');
              if (endInRest == -1) {
                skippingThink = true;
                content = before;
              } else {
                content = before + restAfterStart.substring(endInRest + 8);
              }
            } else if (content.startsWith('</think>')) {
              content = content.substring(8);
            }
            if (content.isNotEmpty) yield content;
          } catch (_) {}
        }
      }
    }
  }

  String _friendlyError(int status, String body) {
    if (status == 401 || status == 403) return '$name rejected the API key.';
    if (status == 404) return 'This $name model is unavailable. Pick another one.';
    if (status == 429) return '$name free limit reached. Wait a minute and try again.';
    if (status >= 500) return '$name servers are busy. Try again shortly.';
    return '$name error $status: $body';
  }
}
