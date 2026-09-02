# Banataq Intelligence Layer

Phase 2 of Banataq's evolution: the intelligence foundation that turns the
Workspace app into an **AI operating system**. This document describes the
architecture, the components, and how to use them.

## Principles

- **Clean architecture** — domain contracts in `domain/`, concrete
  implementations in `data/`, orchestration in `application/`. Dependencies
  point inward; the brain never imports HTTP or persistence code.
- **Offline-first** — the default engine runs fully offline (mock + local
  providers, in-memory + `SharedPreferences` stores, hashing embeddings). No
  network, no API key, no crash.
- **Provider-agnostic** — LLMs plug in behind one abstraction. A new model is a
  new `LlmProvider`, nothing else changes.
- **Testable** — every component is deterministic and unit-tested (72 tests).

## Layout

```
lib/features/intelligence/
├── intelligence.dart              # public barrel
├── domain/
│   ├── models/                    # immutable data types
│   └── providers/                 # abstract contracts (interfaces)
├── data/
│   └── providers/                 # concrete implementations
└── application/                   # orchestrators & engines
```

## The pipeline (one brain turn)

`IntelligenceBrain.chat(...)` runs:

1. **Short-term memory** — the user message is appended to the conversation
   transcript (`ChatHistoryStore`).
2. **Long-term recall** — relevant memories are retrieved from `MemoryStore`
   (keyword relevance, falling back to importance-ranked memories).
3. **RAG retrieval** — `RagEngine` embeds the query and returns the nearest
   indexed workspace chunks.
4. **Prompt assembly** — `PromptAssembler` composes the system prompt
   (persona → instructions → memories → retrieved knowledge → tool catalogue)
   and `ContextCompressor` fits the history into the token budget, summarising
   whatever is dropped.
5. **Model call** — the provider answers. If it requests tools, `ToolRunner`
   executes them and the loop continues (bounded by `maxToolIterations`).
6. **Memory extraction** — `MemoryExtractor` turns explicit statements
   ("remember that …") into durable long-term memories.
7. **Persistence** — the assistant reply is appended to the transcript.

`streamChat(...)` runs the same pipeline but emits text deltas live and still
executes tools.

## Key abstractions

| Contract | Responsibility | Offline default |
| --- | --- | --- |
| `LlmProvider` | Generate text / tool calls (sync or streamed) | `MockLlmProvider`, `LocalLlmProvider` |
| `MemoryStore` | Durable long-term memory | `InMemoryMemoryStore`, `PersistentMemoryStore` |
| `ChatHistoryStore` | Per-conversation transcript | `InMemoryChatHistoryStore`, `PersistentChatHistoryStore` |
| `EmbeddingGenerator` | Text → vector | `HashingEmbeddingGenerator` |
| `VectorStore` | Nearest-neighbour search | `InMemoryVectorStore` |
| `Tokenizer` | Token counting for budgets | `SimpleTokenizer` |
| `ContextCompressor` | Trim + summarise history | `DefaultContextCompressor` |
| `PromptAssembler` | Compose system prompt + window | `DefaultPromptAssembler` |
| `ToolRunner` | Execute model-requested tools | `ToolRunnerImpl` |
| `MemoryExtractor` | Learn from user turns | `SimpleMemoryExtractor` |

## Streaming

Providers expose `Stream<LlmStreamEvent>` with `LlmTextDelta`,
`LlmToolCallEvent` and `LlmDoneEvent`. The brain consumes these, yields text to
the caller, and assembles tool calls for execution. `LlmCapability` lets the
brain detect providers that lack streaming (it falls back to `complete`).

## Tool-calling framework

`ToolDefinition` is the schema advertised to the model; `ToolRunner` maps names
to `ToolExecutor` callbacks. The workspace brain registers:

- `search_workspace` — full-workspace search
- `list_files`, `get_memories`, `workspace_briefing` — reads
- `complete_task`, `summarize_file` — mutations through `WorkspaceRepository`

Add a tool by registering a definition + executor; the model discovers it
automatically on the next turn.

## Workspace integration

`WorkspaceKnowledgeAdapter` turns workspace content (files, memories, sessions,
timeline) into RAG documents, so answers are grounded in real data and the
`sources` in `BrainReply` can be cited. `WorkspaceBrainFactory` builds a
ready-to-use engine:

```dart
final engine = await WorkspaceBrainFactory.build(
  repository: WorkspaceRepository(),
);
final reply = await engine.brain.chat(
  conversationId: 'demo',
  userMessage: 'What files mention suppliers?',
);
// reply.sources, reply.memoriesUsed, reply.toolResults, reply.usage
```

## Pluggable LLMs

`LlmProviderFactory` maps `LlmProviderType` (mock / local / openai / gemini) to
a provider. Remote adapters (`OpenAiLlmProvider`, `GeminiLlmProvider`) translate
the neutral request/response types, including function calling and SSE
streaming. To add a model: implement `LlmProvider`, add an enum value and a
factory branch.

## Usage

```dart
// Offline default, ready to chat:
final engine = IntelligenceEngine.offline();
final reply = await engine.brain.chat(
  conversationId: 'c1',
  userMessage: 'remember that the venue is the town hall',
);
print(reply.text);
```

```dart
// Streaming:
await for (final chunk in engine.brain.streamChat(
  conversationId: 'c1',
  userMessage: 'Write a welcome note',
)) {
  // append chunk to UI
}
```

## Tests

`test/features/intelligence/` covers the tokenizer, embeddings, vector store,
memory (in-memory + persistent), chat history, compressor, prompt assembler,
tool runner, RAG engine, memory extractor, providers (mock/local/factory) and
the brain end-to-end, plus workspace integration.
