import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/long_term_memory.dart';
import '../../domain/providers/memory_store.dart';
import 'in_memory_memory_store.dart';

/// Offline-first long-term memory that survives app restarts.
///
/// Delegates queries to an in-memory store and persists every mutation to
/// [SharedPreferences] as JSON. This is the production default for long-term
/// memory; swapping in a hosted memory service only requires implementing
/// [MemoryStore].
class PersistentMemoryStore implements MemoryStore {
  PersistentMemoryStore({MemoryStore? backing}) {
    _backing = backing ?? InMemoryMemoryStore();
  }

  static const _key = 'intelligence.long_term_memory.v1';

  late final MemoryStore _backing;
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      await _backing.addAll([
        for (final item in list) _memoryFromJson(item as Map<String, dynamic>),
      ]);
    } catch (_) {
      // Corrupt data is dropped rather than crashing the brain.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final memories = await _backing.all();
    await prefs.setString(
      _key,
      jsonEncode(memories.map(_memoryToJson).toList()),
    );
  }

  @override
  Future<List<LongTermMemory>> all() async {
    await _ensureLoaded();
    return _backing.all();
  }

  @override
  Future<void> add(LongTermMemory memory) async {
    await _ensureLoaded();
    await _backing.add(memory);
    await _persist();
  }

  @override
  Future<void> addAll(List<LongTermMemory> memories) async {
    await _ensureLoaded();
    await _backing.addAll(memories);
    await _persist();
  }

  @override
  Future<LongTermMemory?> get(String id) async {
    await _ensureLoaded();
    return _backing.get(id);
  }

  @override
  Future<void> delete(String id) async {
    await _ensureLoaded();
    await _backing.delete(id);
    await _persist();
  }

  @override
  Future<List<LongTermMemory>> search(String query, {int limit = 10}) async {
    await _ensureLoaded();
    return _backing.search(query, limit: limit);
  }

  @override
  Future<List<LongTermMemory>> recent({int limit = 10}) async {
    await _ensureLoaded();
    return _backing.recent(limit: limit);
  }

  @override
  Future<List<LongTermMemory>> important({int limit = 10}) async {
    await _ensureLoaded();
    return _backing.important(limit: limit);
  }

  @override
  Future<void> touch(String id) async {
    await _ensureLoaded();
    await _backing.touch(id);
    await _persist();
  }
}

Map<String, dynamic> _memoryToJson(LongTermMemory m) => {
      'id': m.id,
      'type': m.type.name,
      'content': m.content,
      'title': m.title,
      'importance': m.importance,
      'source': m.source,
      'createdAt': m.createdAt?.toIso8601String(),
      'lastAccessedAt': m.lastAccessedAt?.toIso8601String(),
      'accessCount': m.accessCount,
      'tags': m.tags,
    };

LongTermMemory _memoryFromJson(Map<String, dynamic> json) => LongTermMemory(
      id: json['id'] as String,
      type: MemoryEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MemoryEntryType.fact,
      ),
      content: json['content'] as String,
      title: json['title'] as String?,
      importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
      source: json['source'] as String?,
      createdAt: _parseDate(json['createdAt']),
      lastAccessedAt: _parseDate(json['lastAccessedAt']),
      accessCount: json['accessCount'] as int? ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    );

DateTime? _parseDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
