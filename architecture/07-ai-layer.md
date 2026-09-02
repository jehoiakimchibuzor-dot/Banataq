# AI Layer Architecture

## Full AI Pipeline

```
User Input
    |
    v
[Prompt Manager]          -- Builds prompt with persona, memories, context
    |
    v
[Model Router]            -- Selects model based on task complexity
    |
    v
[Tool Resolver]           -- Decides if function calling is needed
    |
    v
[Provider Adapter]        -- Routes to OpenAI / Gemini / Claude / DeepSeek
    |
    v
[Response Stream]         -- Streams tokens to UI
    |
    v
[Memory Extractor]        -- Extracts facts, preferences from conversation
    |
    v
[RAG Engine]              -- Retrieves relevant documents/knowledge
    |
    v
[Agent Runtime]           -- Executes multi-step tasks (future)
```

## 1. Provider Abstraction (Extended)

```dart
abstract class AiProvider {
  String get name;
  bool get supportsStreaming;
  bool get supportsFunctions;
  bool get supportsVision;
  bool get supportsToolCalling;

  Future<String> generateResponse({
    required String prompt,
    String? persona,
    List<Map<String, String>>? history,
    List<Memory>? memories,
  });

  Stream<String> generateResponseStream({
    required String prompt,
    String? persona,
    List<Map<String, String>>? history,
    List<Memory>? memories,
  });

  Future<AiFunctionResponse> generateWithFunctions({
    required String prompt,
    required List<AiFunction> functions,
  });

  Future<String> generateWithVision({
    required String prompt,
    required Uint8List imageBytes,
    String? persona,
  });

  Future<String> generateWithRag({
    required String prompt,
    required List<RagDocument> contextDocuments,
  });
}
```

## 2. Model Router

```dart
class ModelRouter {
  final Map<String, AiProvider> _providers;
  final CostTracker _costTracker;

  // Route to the best model for the task
  AiProvider resolve(TaskType task) {
    return switch (task) {
      TaskType.simpleChat    => _cheapestProvider(),
      TaskType.code          => _bestCodingProvider(),
      TaskType.vision        => _bestVisionProvider(),
      TaskType.complexReason => _mostCapableProvider(),
      TaskType.quickReply    => _fastestProvider(),
    };
  }

  // Fallback chain
  Future<String> generateWithFallback({
    required String prompt,
    required List<AiProvider> preferredChain,
  }) async {
    for (final provider in preferredChain) {
      try {
        return await provider.generateResponse(prompt: prompt);
      } on AiException {
        continue; // Try next provider
      }
    }
    return _localAssistant.reply(prompt); // Final fallback
  }
}

enum TaskType {
  simpleChat,       // "What's the weather?"
  quickReply,       // "Summarize this"
  code,             // "Write a Python function"
  complexReason,    // "Explain quantum computing"
  vision,           // "What's in this image?"
  translation,      // Hausa/English
  studyHelp,        // Exam questions
  businessWrite,    // Captions, invoices
}
```

## 3. Cost Management

```dart
class CostManager {
  final Map<String, ModelCost> _modelCosts = {
    'gpt-4o':         ModelCost(input: 2.50,  output: 10.00),  // per 1M tokens
    'gpt-4o-mini':    ModelCost(input: 0.15,  output: 0.60),
    'gemini-2.0-flash': ModelCost(input: 0.10, output: 0.40),
    'claude-3-haiku': ModelCost(input: 0.25,  output: 1.25),
    'local':          ModelCost(input: 0,     output: 0),
  };

  // Track usage per session
  TokenUsage _currentSession = TokenUsage.empty();

  Future<void> trackTokens({
    required String model,
    required int inputTokens,
    required int outputTokens,
    required String userId,
  }) async {
    _currentSession = _currentSession.add(model, inputTokens, outputTokens);
    await _persistUsage(userId, model, inputTokens, outputTokens);
  }

  double estimateCost(String model, int inputTokens, int outputTokens) {
    final cost = _modelCosts[model];
    if (cost == null) return 0;
    return (inputTokens / 1_000_000 * cost.input) +
           (outputTokens / 1_000_000 * cost.output);
  }

  // Budget enforcement
  Future<bool> withinBudget(String userId) async {
    final monthly = await _getMonthlyUsage(userId);
    final limit = await _getUserLimit(userId);
    return monthly.cost < limit;
  }
}

class TokenUsage {
  final int totalInputTokens;
  final int totalOutputTokens;
  final double totalCost;
}
```

## 4. Provider & Model Support Matrix

| Feature | OpenAI | Gemini | Claude | DeepSeek | Local |
|---------|--------|--------|--------|----------|-------|
| Text generation | Yes | Yes | Yes | Yes | Yes |
| Streaming | Yes | Yes | Yes | Yes | No |
| Function calling | Yes | Yes | Yes | Yes | No |
| Vision | GPT-4o | Yes | Claude 3 | N/A | No |
| Tool calling | Yes | Yes | Yes | Yes | No |
| Cost | $$$ | $ | $$ | $ | Free |
| Offline | No | No | No | No | Yes |

## 5. Prompt Manager

```dart
class PromptManager {
  final RemoteConfig _remoteConfig;

  String buildPrompt({
    required String userInput,
    String? persona,
    List<Memory>? memories,
    List<String>? capabilities,
  }) {
    final systemPrompt = _remoteConfig.getString('system_prompt_template');
    final memoryContext = memories?.map((m) => '- ${m.key}: ${m.value}').join('\n');

    return '''
$systemPrompt
${persona != null ? 'User is a: $persona' : ''}
${memoryContext != null ? '## User Context\n$memoryContext' : ''}
${capabilities != null ? '## Available Skills\n${capabilities.join(', ')}' : ''}

## User Input
$userInput
''';
  }
}
```

## 6. RAG Engine (Future)

```dart
class RagEngine {
  Future<String> augmentPrompt({
    required String userInput,
    required String userId,
  }) async {
    final query = await _generateEmbedding(userInput);
    final documents = await _vectorDb.search(
      embedding: query,
      topK: 5,
      userId: userId,
    );
    final context = documents.map((d) => d.content).join('\n\n---\n\n');
    return 'Context:\n$context\n\nQuestion:\n$userInput';
  }
}
```

## 7. Implementation Phasing

| Phase | AI Capability | When |
|-------|--------------|------|
| Current | Text generation, 3 providers | Now |
| Phase 1 | Streaming | Week 1-2 |
| Phase 2 | Memory injection | Week 3 |
| Phase 3 | Vision, file understanding | Week 4-5 |
| Phase 4 | Student intelligence prompts | Week 6-7 |
| Phase 5 | Cost tracking + model routing | Week 8-9 |
| Phase 6 | RAG pipeline | Week 12-13 |
| Phase 7 | Agent runtime | Week 14-16 |
