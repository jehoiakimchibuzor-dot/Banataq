import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/intelligence_message.dart';
import '../../domain/providers/chat_history_store.dart';
import 'in_memory_chat_history_store.dart';

/// Offline-first short-term conversation memory that survives app restarts.
///
/// Delegates to an in-memory store and persists each conversation as JSON.
class PersistentChatHistoryStore implements ChatHistoryStore {
  PersistentChatHistoryStore({ChatHistoryStore? backing}) {
    _backing = backing ?? InMemoryChatHistoryStore();
  }

  static const _key = 'intelligence.chat_history.v1';

  late final ChatHistoryStore _backing;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final messages = (entry.value as List)
            .map(
              (item) => _messageFromJson(item as Map<String, dynamic>),
            )
            .toList();
        for (final message in messages) {
          await _backing.append(entry.key, message);
        }
      }
    } catch (_) {
      // Corrupt data is dropped rather than crashing the brain.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _backing.conversationIds();
    final data = <String, dynamic>{};
    for (final id in ids) {
      final messages = await _backing.messages(id, limit: 200);
      data[id] = messages.map(_messageToJson).toList();
    }
    await prefs.setString(_key, jsonEncode(data));
  }

  @override
  Future<void> append(
    String conversationId,
    IntelligenceMessage message,
  ) async {
    await _ensureLoaded();
    await _backing.append(conversationId, message);
    await _persist();
  }

  @override
  Future<List<IntelligenceMessage>> messages(
    String conversationId, {
    int limit = 50,
  }) async {
    await _ensureLoaded();
    return _backing.messages(conversationId, limit: limit);
  }

  @override
  Future<void> clear(String conversationId) async {
    await _ensureLoaded();
    await _backing.clear(conversationId);
    await _persist();
  }

  @override
  Future<List<String>> conversationIds() async {
    await _ensureLoaded();
    return _backing.conversationIds();
  }
}

Map<String, dynamic> _messageToJson(IntelligenceMessage m) => {
      'role': m.role.name,
      'content': m.content,
      if (m.name != null) 'name': m.name,
      if (m.toolCallId != null) 'toolCallId': m.toolCallId,
    };

IntelligenceMessage _messageFromJson(Map<String, dynamic> json) =>
    IntelligenceMessage(
      role: IntelligenceRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => IntelligenceRole.user,
      ),
      content: json['content'] as String? ?? '',
      name: json['name'] as String?,
      toolCallId: json['toolCallId'] as String?,
    );
