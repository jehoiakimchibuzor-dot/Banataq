import '../models/intelligence_message.dart';

/// Short-term, per-conversation working memory (the rolling transcript).
abstract interface class ChatHistoryStore {
  Future<void> append(String conversationId, IntelligenceMessage message);

  Future<List<IntelligenceMessage>> messages(
    String conversationId, {
    int limit = 50,
  });

  Future<void> clear(String conversationId);

  Future<List<String>> conversationIds();
}
