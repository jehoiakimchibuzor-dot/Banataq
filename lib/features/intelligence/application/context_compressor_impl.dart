import '../domain/models/compressed_context.dart';
import '../domain/models/intelligence_message.dart';
import '../domain/providers/context_compressor.dart';
import '../domain/providers/tokenizer.dart';
import '../data/providers/simple_tokenizer.dart';

/// Token-budget context compressor.
///
/// Keeps the system message and the *newest* messages; when the window exceeds
/// [budgetTokens] the oldest non-system messages are dropped and folded into a
/// running [CompressedContext.summary] so no meaning is lost silently.
class DefaultContextCompressor implements ContextCompressor {
  DefaultContextCompressor({Tokenizer? tokenizer, this.summarizer})
      : _tokenizer = tokenizer ?? const SimpleTokenizer();

  final Tokenizer _tokenizer;

  /// Builds a natural-language summary from a list of dropped messages.
  final String Function(List<IntelligenceMessage> dropped, String? prior)?
      summarizer;

  @override
  CompressedContext compress({
    required List<IntelligenceMessage> messages,
    required int budgetTokens,
    String? runningSummary,
  }) {
    if (messages.isEmpty) {
      return CompressedContext(messages: messages, estimatedTokens: 0);
    }
    if (budgetTokens <= 0) {
      return CompressedContext(
        messages: const [],
        estimatedTokens: 0,
        summary: runningSummary,
        droppedCount: messages.length,
      );
    }

    final systemMessages =
        messages.where((m) => m.role == IntelligenceRole.system).toList();
    final rest =
        messages.where((m) => m.role != IntelligenceRole.system).toList();

    final systemTokens = _countAll(systemMessages);
    final summaryTokens =
        runningSummary == null ? 0 : _tokenizer.countTokens(runningSummary);
    var budgetLeft = budgetTokens - systemTokens - summaryTokens;

    final retained = <IntelligenceMessage>[];
    final dropped = <IntelligenceMessage>[];
    for (final message in rest.reversed) {
      final tokens = _tokenizer.countTokens(message.content);
      if (tokens <= budgetLeft) {
        retained.insert(0, message);
        budgetLeft -= tokens;
      } else {
        dropped.insert(0, message);
      }
    }

    final all = [...systemMessages, ...retained];
    final summary = dropped.isEmpty
        ? runningSummary
        : summarizer?.call(dropped, runningSummary) ??
            _defaultSummary(dropped, runningSummary);

    return CompressedContext(
      messages: all,
      estimatedTokens:
          _countAll(all) + (summary == null ? 0 : _tokenizer.countTokens(summary)),
      summary: summary,
      droppedCount: dropped.length,
    );
  }

  int _countAll(List<IntelligenceMessage> messages) => messages.fold(
        0,
        (sum, m) => sum + _tokenizer.countTokens(m.content),
      );

  static String _defaultSummary(
    List<IntelligenceMessage> dropped,
    String? prior,
  ) {
    final parts = [
      if (prior != null && prior.isNotEmpty) prior,
      'Earlier context: ${dropped.map((m) => '${m.role.name}: ${m.content}').join(' | ')}',
    ];
    final joined = parts.join(' | ');
    final max = joined.length > 300 ? 300 : joined.length;
    return joined.substring(0, max);
  }
}
