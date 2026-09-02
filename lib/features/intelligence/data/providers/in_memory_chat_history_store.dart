import '../../domain/models/intelligence_message.dart';
import '../../domain/providers/chat_history_store.dart';

/// Reference short-term conversation memory: per-conversation message lists.
class InMemoryChatHistoryStore implements ChatHistoryStore {
  final Map<String, List<IntelligenceMessage>> _conversations = {};

  @override
  Future<void> append(
    String conversationId,
    IntelligenceMessage message,
  ) async {
    _conversations.putIfAbsent(conversationId, () => []).add(message);
  }

  @override
  Future<List<IntelligenceMessage>> messages(
    String conversationId, {
    int limit = 50,
  }) async {
    final list = _conversations[conversationId] ?? const [];
    if (list.length <= limit) return List.of(list);
    return list.sublist(list.length - limit);
  }

  @override
  Future<void> clear(String conversationId) async {
    _conversations.remove(conversationId);
  }

  @override
  Future<List<String>> conversationIds() async =>
      List.of(_conversations.keys);
}
