import '../models/compressed_context.dart';
import '../models/intelligence_message.dart';

/// Trims a conversation window to a token budget, keeping the newest messages
/// and summarising the oldest so nothing is silently lost.
abstract interface class ContextCompressor {
  CompressedContext compress({
    required List<IntelligenceMessage> messages,
    required int budgetTokens,
    String? runningSummary,
  });
}
