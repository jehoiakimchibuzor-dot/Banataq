import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/ollama_config.dart';
import 'ai_provider.dart';

class OllamaAiProvider implements AiProvider {
  final String baseUrl;
  final String model;

  OllamaAiProvider({String? baseUrl, String? model})
      : baseUrl = baseUrl ?? OllamaConfig.defaultBaseUrl,
        model = model ?? OllamaConfig.model;

  @override
  String get name => 'Ollama';

  String get _apiBase => baseUrl.replaceFirst(RegExp(r'/v1$'), '');

  Uri get _endpoint => Uri.parse('$_apiBase/api/chat');

  Future<void> warmup() async {
    try {
      await http
          .post(
            Uri.parse('$_apiBase/api/generate'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': 'ping',
              'keep_alive': -1,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 120));
    } catch (_) {}
  }

  /// Lightweight reachability probe: hits the Ollama API root and returns
  /// true if the server answered (status < 500).
  Future<bool> testConnection() async {
    final res = await http
        .get(Uri.parse('$_apiBase/api/tags'))
        .timeout(const Duration(seconds: 5));
    return res.statusCode < 500;
  }

  String _systemPrompt(String? persona, String? displayName) {
    final namePart = displayName != null && displayName.trim().isNotEmpty
        ? ' The user\'s name is $displayName. Always greet them warmly by name at the very start (e.g. "Hi $displayName,") and remember this name.'
        : '';
    if (persona != null) {
      return 'You are Banataq, an AI assistant helping a $persona user.$namePart Respond concisely and practically for the Nigerian/African context.';
    }
    return 'You are Banataq, a helpful AI assistant.$namePart Respond concisely and practically.';
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

  @override
  Future<String> generateResponse(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async {
    final messages = _buildMessages(prompt, persona, displayName, history);
    final res = await http
        .post(
          _endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'stream': false,
            'think': false,
            'options': {'temperature': 0.7, 'num_predict': 2000},
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Ollama API error: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final message = data['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Ollama returned an empty response. The model may still be loading.');
    }
    return content;
  }

  @override
  Stream<String> generateResponseStream(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async* {
    final messages = _buildMessages(prompt, persona, displayName, history);
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': true,
      'think': false,
      'options': {'temperature': 0.7, 'num_predict': 2000},
    });

    final request = http.Request('POST', _endpoint);
    request.headers.addAll(const {'Content-Type': 'application/json'});
    request.body = body;

    final response = await http.Client().send(request).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Ollama API error: ${response.statusCode}');
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        try {
          final json = jsonDecode(trimmed) as Map<String, dynamic>;
          final message = json['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
          if (json['done'] == true) return;
        } catch (_) {}
      }
    }
  }
}
