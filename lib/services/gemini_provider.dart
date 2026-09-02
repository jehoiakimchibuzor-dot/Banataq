import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

class GeminiProvider implements AiProvider {
  final String apiKey;
  final String model;

  GeminiProvider(this.apiKey, {this.model = 'gemini-3.7-flash'});

  @override
  String get name => 'Gemini';

  String get _endpoint => 'https://generativelanguage.googleapis.com/v1beta/models/$model';

  /// Probes the key against the list-models endpoint. Returns a friendly
  /// message describing whether the key is valid and can reach Gemini.
  Future<String> testConnection() async {
    final res = await http.get(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
    );
    if (res.statusCode == 200) {
      return 'Connected to Gemini ($model). Your key works!';
    }
    if (res.statusCode == 400) {
      return 'Gemini API error: the model "$model" may not be available on the free tier.';
    }
    if (res.statusCode == 403) {
      return 'Your key was rejected. It may be invalid or needs the free tier enabled in Google AI Studio.';
    }
    if (res.statusCode == 429) {
      return 'Rate limit hit on the free tier. Wait a minute and try again.';
    }
    return 'Gemini API error: ${res.statusCode} ${res.body}';
  }

  @override
  Future<String> generateResponse(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async {
    final today = _todayString();
    final parts = <Map<String, dynamic>>[
      {
        'text': _contextText(persona, displayName, today, prompt),
      },
    ];

    if (history != null && history.length > 2) {
      final recent = history.sublist(history.length - 4);
      for (final msg in recent) {
        if (msg['role'] == 'user') {
          parts.insert(parts.length - 1, {'text': 'User: ${msg['content']}'});
        } else {
          parts.insert(parts.length - 1, {'text': 'Assistant: ${msg['content']}'});
        }
      }
    }

    final payload = <String, dynamic>{
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {'maxOutputTokens': 2000, 'temperature': 0.7},
    };
    if (_needsSearch(prompt)) {
      payload['tools'] = [
        {'google_search': {}}
      ];
    }

    final res = await http.post(
      Uri.parse('$_endpoint:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception(_friendlyError(status: res.statusCode, body: res.body));
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    try {
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    } catch (_) {
      throw Exception('Unexpected Gemini response format');
    }
  }

  @override
  Stream<String> generateResponseStream(
    String prompt, {
    String? persona,
    String? displayName,
    List<Map<String, String>>? history,
  }) async* {
    final today = _todayString();
    final parts = <Map<String, dynamic>>[
      {
        'text': _contextText(persona, displayName, today, prompt),
      },
    ];

    final payload = <String, dynamic>{
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {'maxOutputTokens': 2000, 'temperature': 0.7},
    };
    if (_needsSearch(prompt)) {
      payload['tools'] = [
        {'google_search': {}}
      ];
    }

    final request = http.Request(
      'POST',
      Uri.parse('$_endpoint:streamGenerateContent?alt=sse&key=$apiKey'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(payload);

    final response = await http.Client().send(request);

    // Surface HTTP failures (retired model, quota, bad key) instead of
    // silently yielding nothing, which showed as a blank reply in chat.
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception(_friendlyError(status: response.statusCode, body: body));
    }

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (line.startsWith('data: ')) {
          try {
            final json = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          } catch (_) {}
        }
      }
    }
  }

  String _friendlyError({required int status, required String body}) {
    if (status == 404) {
      return 'This Gemini model is no longer available. Pick another one in Settings.';
    }
    if (status == 403 || status == 401) {
      return 'Gemini rejected the API key (HTTP $status). Clear any saved key in Settings so the built-in one is used, or paste a fresh key.';
    }
    if (status == 400) {
      return 'Gemini rejected the request. The saved API key may be malformed — clear it in Settings to use the built-in key.';
    }
    if (status == 429) {
      return 'Free-tier rate limit reached. Wait a minute and try again.';
    }
    if (status >= 500) {
      return 'Gemini servers are busy right now. Try again shortly.';
    }
    return 'Gemini error $status: $body';
  }

  String _contextText(
      String? persona, String? displayName, String today, String prompt) {
    final name = displayName?.trim();
    // Only greet by name if we actually know it, and not on every turn — let model decide when natural
    final namePart = (name != null && name.isNotEmpty) ? ' The user is $name — use their name occasionally when natural, not every reply.' : '';
    final personaPart = persona != null && persona.isNotEmpty
        ? 'You are Banataq helping a $persona user.$namePart'
        : 'You are Banataq, a helpful AI assistant.$namePart';
    // Only mention date when search grounding is relevant, to avoid weird date chatter
    final timePart = _needsSearch(prompt) ? ' Today is $today. Your cutoff is Jan 2026 — use Google Search for newer info.' : '';
    return 'Context: $personaPart Respond concisely for Nigerian/African context.$timePart\n\nUser: $prompt';
  }

  String _todayString() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  bool _needsSearch(String prompt) {
    final q = prompt.toLowerCase();
    return q.contains('today') ||
        q.contains('now') ||
        q.contains('latest') ||
        q.contains('current') ||
        q.contains('news') ||
        q.contains('this week') ||
        q.contains('this month') ||
        q.contains('this year') ||
        q.contains('2026') ||
        q.contains('price') ||
        q.contains('score') ||
        q.contains('weather') ||
        q.contains('search') ||
        q.contains('recent');
  }
}
