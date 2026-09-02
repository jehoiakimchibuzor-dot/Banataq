import 'intelligence_message.dart';
import 'long_term_memory.dart';
import 'rag_chunk.dart';

/// The fully-assembled prompt prepared for the model.
///
/// Produced by a [PromptAssembler]. [systemPrompt] is the final system text
/// (persona + instructions + memories + retrieved documents + tools + summary
/// of truncated history); [messages] holds the conversation window including
/// the current user turn.
class AssembledContext {
  const AssembledContext({
    required this.systemPrompt,
    required this.messages,
    required this.estimatedTokens,
    this.documentsUsed = const [],
    this.memoriesUsed = const [],
    this.droppedHistoryCount = 0,
  });

  final String systemPrompt;
  final List<IntelligenceMessage> messages;
  final int estimatedTokens;

  /// RAG chunks that were injected into the prompt.
  final List<RagChunk> documentsUsed;

  /// Long-term memories injected into the prompt.
  final List<LongTermMemory> memoriesUsed;

  /// Number of history messages dropped by the context compressor.
  final int droppedHistoryCount;
}
