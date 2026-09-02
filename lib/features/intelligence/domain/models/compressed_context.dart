import 'intelligence_message.dart';

/// Result of context compression: the trimmed message window plus a running
/// summary of whatever was dropped.
class CompressedContext {
  const CompressedContext({
    required this.messages,
    required this.estimatedTokens,
    this.summary,
    this.droppedCount = 0,
  });

  final List<IntelligenceMessage> messages;
  final int estimatedTokens;

  /// Natural-language summary of the dropped (oldest) messages.
  final String? summary;

  final int droppedCount;
}
