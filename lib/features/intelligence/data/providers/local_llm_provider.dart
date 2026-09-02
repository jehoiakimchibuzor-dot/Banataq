import 'dart:async';

import '../../domain/models/chat_usage.dart';
import '../../domain/models/intelligence_message.dart';
import '../../domain/models/llm_request.dart';
import '../../domain/models/llm_response.dart';
import '../../domain/models/llm_stream_event.dart';
import '../../domain/providers/llm_provider.dart';
import '../../domain/providers/tokenizer.dart';
import 'simple_tokenizer.dart';

/// Offline, rule-based assistant — the legacy chat brain, adapted to the
/// provider interface so it can be dropped into the Intelligence Layer.
///
/// It is genuinely useful for common intents (summaries, exam help, business
/// writing, announcements) and streams word-by-word.
class LocalLlmProvider implements LlmProvider {
  LocalLlmProvider({Tokenizer? tokenizer})
      : tokenizer = tokenizer ?? const SimpleTokenizer();

  final Tokenizer tokenizer;

  @override
  String get name => 'Local';

  @override
  Set<LlmCapability> get capabilities => {LlmCapability.streaming};

  @override
  int get contextWindow => 4096;

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    final text = _answer(_lastUserMessage(request.messages));
    return LlmResponse(
      content: text,
      usage: ChatUsage(
        promptTokens: tokenizer.countTokens(request.systemPrompt ?? '') +
            tokenizer.countTokens(_lastUserMessage(request.messages)),
        completionTokens: tokenizer.countTokens(text),
      ),
    );
  }

  @override
  Stream<LlmStreamEvent> stream(LlmRequest request) async* {
    final text = _answer(_lastUserMessage(request.messages));
    for (final word in text.split(' ')) {
      yield LlmTextDelta('$word ');
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    yield LlmDoneEvent(
      ChatUsage(
        promptTokens: tokenizer.countTokens(request.systemPrompt ?? ''),
        completionTokens: tokenizer.countTokens(text),
      ),
    );
  }

  static String _lastUserMessage(List<IntelligenceMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == IntelligenceRole.user) {
        return messages[i].content;
      }
    }
    return '';
  }

  static String _answer(String input) {
    final text = input.toLowerCase();
    if (text.contains('summar')) {
      return 'Paste the note you want summarized. I will turn it into clear '
          'bullet points, key definitions, and likely exam questions.';
    }
    if (text.contains('exam') ||
        text.contains('question') ||
        text.contains('assignment')) {
      return 'Send the exact question. I will explain the meaning, show the '
          'steps, and help you build an answer without making it confusing.';
    }
    if (text.contains('caption') ||
        text.contains('post') ||
        text.contains('announce')) {
      return 'Tell me what you are announcing, who should see it, and the '
          'tone you want. I can make it short for WhatsApp, clean for '
          'Instagram, or formal for LinkedIn.';
    }
    if (text.contains('business') || text.contains('sell')) {
      return 'Tell me the product, price, location, and why people should '
          'trust it. I will write a clean business description and '
          'customer-facing pitch.';
    }
    return 'I can help with studying, writing, business ideas, summaries, '
        'explanations, and planning. Give me the task and I will structure '
        'the answer clearly.';
  }
}
