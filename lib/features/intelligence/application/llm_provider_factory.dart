import 'package:http/http.dart' as http;

import '../data/providers/gemini_llm_provider.dart';
import '../data/providers/local_llm_provider.dart';
import '../data/providers/mock_llm_provider.dart';
import '../data/providers/ollama_llm_provider.dart';
import '../data/providers/openai_llm_provider.dart';
import '../domain/models/llm_provider_type.dart';
import '../domain/providers/llm_provider.dart';

/// Maps a [LlmProviderType] to a concrete [LlmProvider].
///
/// This is the single seam where a new LLM plugs in: add an enum value and a
/// branch here; the Brain, RAG, memory and tool layers never change.
class LlmProviderFactory {
  const LlmProviderFactory({this.client});

  /// Injectable HTTP client so remote adapters stay testable.
  final http.Client? client;

  LlmProvider create(
    LlmProviderType type, {
    String? apiKey,
    String? baseUrl,
    String? model,
  }) {
    switch (type) {
      case LlmProviderType.mock:
        return MockLlmProvider();
      case LlmProviderType.local:
        return LocalLlmProvider();
      case LlmProviderType.openai:
        final key = apiKey;
        if (key == null || key.isEmpty) {
          throw ArgumentError('An API key is required for OpenAI.');
        }
        return OpenAiLlmProvider(apiKey: key, client: client);
      case LlmProviderType.gemini:
        final key = apiKey;
        if (key == null || key.isEmpty) {
          throw ArgumentError('An API key is required for Gemini.');
        }
        return GeminiLlmProvider(apiKey: key, client: client);
      case LlmProviderType.ollama:
        return OllamaLlmProvider(
          baseUrl: baseUrl,
          model: model,
          client: client,
        );
    }
  }
}
