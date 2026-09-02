import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factory = LlmProviderFactory();

  test('mock and local providers need no configuration', () {
    expect(factory.create(LlmProviderType.mock), isA<MockLlmProvider>());
    expect(factory.create(LlmProviderType.local), isA<LocalLlmProvider>());
  });

  test('ollama needs no API key', () {
    expect(factory.create(LlmProviderType.ollama), isA<OllamaLlmProvider>());
  });

  test('ollama accepts baseUrl and model overrides', () {
    final provider = factory.create(
      LlmProviderType.ollama,
      baseUrl: 'http://10.0.2.2:11434/v1',
      model: 'qwen2.5:1.5b',
    ) as OllamaLlmProvider;
    expect(provider.baseUrl, 'http://10.0.2.2:11434/v1');
    expect(provider.model, 'qwen2.5:1.5b');
  });

  test('remote providers require an API key', () {
    expect(
      () => factory.create(LlmProviderType.openai),
      throwsArgumentError,
    );
    expect(
      () => factory.create(LlmProviderType.gemini),
      throwsArgumentError,
    );
  });

  test('remote providers are constructed with a key', () {
    expect(
      factory.create(LlmProviderType.openai, apiKey: 'sk-test'),
      isA<OpenAiLlmProvider>(),
    );
    expect(
      factory.create(LlmProviderType.gemini, apiKey: 'g-test'),
      isA<GeminiLlmProvider>(),
    );
  });
}
