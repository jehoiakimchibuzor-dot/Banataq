import '../data/providers/hashing_embedding_generator.dart';
import '../data/providers/in_memory_chat_history_store.dart';
import '../data/providers/in_memory_memory_store.dart';
import '../data/providers/in_memory_vector_store.dart';
import '../data/providers/mock_llm_provider.dart';
import '../data/providers/simple_tokenizer.dart';
import '../domain/providers/chat_history_store.dart';
import '../domain/providers/embedding_generator.dart';
import '../domain/providers/llm_provider.dart';
import '../domain/providers/memory_extractor.dart';
import '../domain/providers/memory_store.dart';
import '../domain/providers/prompt_assembler.dart';
import '../domain/providers/tokenizer.dart';
import '../domain/providers/tool_runner.dart';
import '../domain/providers/vector_store.dart';
import 'intelligence_brain.dart';
import 'prompt_assembler_impl.dart';
import 'rag_engine.dart';
import 'simple_memory_extractor.dart';
import 'tool_runner_impl.dart';

/// Wires the Intelligence Layer together with offline-first defaults.
///
/// Swap any dependency by passing a different implementation; nothing else in
/// the layer knows which concrete provider/store it is using.
class IntelligenceEngine {
  IntelligenceEngine({
    required LlmProvider provider,
    MemoryStore? memoryStore,
    ChatHistoryStore? historyStore,
    VectorStore? vectorStore,
    EmbeddingGenerator? embeddings,
    Tokenizer? tokenizer,
    ToolRunner? toolRunner,
    PromptAssembler? assembler,
    MemoryExtractor? memoryExtractor,
  }) {
    _tokenizer = tokenizer ?? const SimpleTokenizer();
    rag = RagEngine(
      embeddings: embeddings ?? const HashingEmbeddingGenerator(),
      store: vectorStore ?? InMemoryVectorStore(),
      tokenizer: _tokenizer,
    );
    this.memoryStore = memoryStore ?? InMemoryMemoryStore();
    this.historyStore = historyStore ?? InMemoryChatHistoryStore();
    this.toolRunner = toolRunner ?? ToolRunnerImpl();
    brain = IntelligenceBrain(
      provider: provider,
      assembler: assembler ??
          DefaultPromptAssembler(tokenizer: _tokenizer),
      memoryStore: this.memoryStore,
      historyStore: this.historyStore,
      rag: rag,
      toolRunner: this.toolRunner,
      tokenizer: _tokenizer,
      memoryExtractor: memoryExtractor ?? const SimpleMemoryExtractor(),
    );
  }

  /// Convenience factory producing a fully-offline engine.
  static IntelligenceEngine offline({LlmProvider? provider}) =>
      IntelligenceEngine(provider: provider ?? MockLlmProvider());

  late final Tokenizer _tokenizer;
  late final RagEngine rag;
  late final MemoryStore memoryStore;
  late final ChatHistoryStore historyStore;
  late final ToolRunner toolRunner;
  late final IntelligenceBrain brain;
}
