import '../models/assembled_context.dart';
import '../models/intelligence_message.dart';
import '../models/long_term_memory.dart';
import '../models/rag_chunk.dart';
import '../models/tool_definition.dart';

/// Everything the [PromptAssembler] needs to build one turn's context.
class AssemblerInput {
  const AssemblerInput({
    required this.userMessage,
    this.persona,
    this.systemInstructions,
    this.history = const [],
    this.memories = const [],
    this.documents = const [],
    this.tools = const [],
    this.tokenBudget = 4096,
  });

  final IntelligenceMessage userMessage;
  final String? persona;
  final String? systemInstructions;

  /// Prior turns (excluding the current user message).
  final List<IntelligenceMessage> history;

  final List<LongTermMemory> memories;
  final List<RagChunk> documents;
  final List<ToolDefinition> tools;
  final int tokenBudget;
}

/// Builds the system prompt (persona + instructions + memories + retrieved
/// knowledge + tools) and compresses the history into a token budget.
abstract interface class PromptAssembler {
  AssembledContext assemble(AssemblerInput input);
}
