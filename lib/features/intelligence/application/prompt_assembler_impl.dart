import '../data/providers/simple_tokenizer.dart';
import '../domain/models/assembled_context.dart';
import '../domain/models/intelligence_message.dart';
import '../domain/providers/context_compressor.dart';
import '../domain/providers/prompt_assembler.dart';
import '../domain/providers/tokenizer.dart';
import 'context_compressor_impl.dart';

/// Default [PromptAssembler].
///
/// Builds the system prompt in this order:
/// 1. persona + system instructions
/// 2. long-term memories (recalled by the brain)
/// 3. retrieved RAG knowledge (with source titles)
/// 4. tool catalogue with usage guidance
/// 5. summary of truncated earlier context
///
/// Then compresses the message history into the remaining token budget and
/// appends the current user message.
class DefaultPromptAssembler implements PromptAssembler {
  DefaultPromptAssembler({ContextCompressor? compressor, Tokenizer? tokenizer})
      : _compressor = compressor ?? DefaultContextCompressor(tokenizer: tokenizer),
        _tokenizer = tokenizer ?? const SimpleTokenizer();

  final ContextCompressor _compressor;
  final Tokenizer _tokenizer;

  @override
  AssembledContext assemble(AssemblerInput input) {
    final memoriesBlock = input.memories.isEmpty
        ? ''
        : '\n\n## Long-term memory\n${input.memories.map((m) => '- [${m.type.name}] ${m.displayTitle}: ${m.content}').join('\n')}';

    final documentsBlock = input.documents.isEmpty
        ? ''
        : '\n\n## Retrieved knowledge (cite by title)\n${input.documents.map((d) => '[${d.title}] ${d.text}').join('\n\n')}';

    final toolsBlock = input.tools.isEmpty
        ? ''
        : '\n\n## Available tools\n${input.tools.map((t) => '- ${t.name}: ${t.description}').join('\n')}'
            '\n\nWhen a user request matches a tool, call it before answering.';

    final personaLine = input.persona == null
        ? 'You are Banataq, an AI operating system for a workspace.'
        : 'You are Banataq, an AI operating system assisting a ${input.persona}.';

    final instructions =
        input.systemInstructions == null ? '' : '\n\n${input.systemInstructions}';

    final systemPrompt = [
      personaLine,
      instructions,
      memoriesBlock,
      documentsBlock,
      toolsBlock,
    ].join();

    final systemTokens = _tokenizer.countTokens(systemPrompt);
    final historyBudget = (input.tokenBudget - systemTokens).clamp(0, 1 << 30);

    final compressed = _compressor.compress(
      messages: input.history,
      budgetTokens: historyBudget,
    );

    final finalSystemPrompt = compressed.summary == null
        ? systemPrompt
        : '$systemPrompt\n\n## Summary of earlier context\n${compressed.summary}';

    final messages = [...compressed.messages, input.userMessage];

    return AssembledContext(
      systemPrompt: finalSystemPrompt,
      messages: messages,
      estimatedTokens: _tokenizer.countTokens(finalSystemPrompt) +
          _countAll(messages),
      documentsUsed: input.documents,
      memoriesUsed: input.memories,
      droppedHistoryCount: compressed.droppedCount,
    );
  }

  int _countAll(List<IntelligenceMessage> messages) => messages.fold(
        0,
        (sum, m) => sum + _tokenizer.countTokens(m.content),
      );
}
