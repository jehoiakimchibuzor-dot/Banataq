import 'chat_usage.dart';
import 'long_term_memory.dart';
import 'rag_chunk.dart';
import 'tool_result.dart';

/// The final, user-facing outcome of a brain turn.
///
/// Carries everything needed to render an answer with citations and to drive
/// analytics: the generated text, the RAG sources that grounded it, the
/// long-term memories recalled, tool results, token usage and latency.
class BrainReply {
  const BrainReply({
    required this.text,
    this.sources = const [],
    this.memoriesUsed = const [],
    this.toolResults = const [],
    this.usage = ChatUsage.empty,
    this.iterations = 1,
    this.latencyMs = 0,
  });

  final String text;
  final List<RagChunk> sources;
  final List<LongTermMemory> memoriesUsed;
  final List<ToolResult> toolResults;
  final ChatUsage usage;

  /// Number of model round trips (1 when no tools were invoked).
  final int iterations;

  final int latencyMs;
}
