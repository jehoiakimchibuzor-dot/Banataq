import '../../domain/models/long_term_memory.dart';
import '../../domain/providers/memory_store.dart';

/// Reference long-term memory: a plain in-memory list with keyword search.
class InMemoryMemoryStore implements MemoryStore {
  final List<LongTermMemory> _memories = [];

  @override
  Future<List<LongTermMemory>> all() async => List.of(_memories);

  @override
  Future<void> add(LongTermMemory memory) async {
    _memories.removeWhere((m) => m.id == memory.id);
    _memories.add(memory);
  }

  @override
  Future<void> addAll(List<LongTermMemory> memories) async {
    for (final memory in memories) {
      await add(memory);
    }
  }

  @override
  Future<LongTermMemory?> get(String id) async {
    for (final memory in _memories) {
      if (memory.id == id) return memory;
    }
    return null;
  }

  @override
  Future<void> delete(String id) async {
    _memories.removeWhere((m) => m.id == id);
  }

  @override
  Future<List<LongTermMemory>> search(
    String query, {
    int limit = 10,
  }) async {
    final terms = _terms(query);
    if (terms.isEmpty) return const [];
    final scored = <(LongTermMemory, int)>[
      for (final memory in _memories)
        (memory, _relevance(memory, terms)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return scored
        .where((entry) => entry.$2 > 0)
        .take(limit)
        .map((entry) => entry.$1)
        .toList();
  }

  @override
  Future<List<LongTermMemory>> recent({int limit = 10}) async {
    final list = List.of(_memories)
      ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return list.take(limit).toList();
  }

  @override
  Future<List<LongTermMemory>> important({int limit = 10}) async {
    final list = List.of(_memories)
      ..sort((a, b) => b.importance.compareTo(a.importance));
    return list.take(limit).toList();
  }

  @override
  Future<void> touch(String id) async {
    for (var i = 0; i < _memories.length; i++) {
      if (_memories[i].id == id) {
        _memories[i] = _memories[i].copyWith(
          accessCount: _memories[i].accessCount + 1,
          lastAccessedAt: DateTime.now(),
        );
        return;
      }
    }
  }

  static Set<String> _terms(String query) =>
      query.toLowerCase().split(RegExp(r'[^a-z0-9]+')).toSet()
        ..remove('');

  static int _relevance(LongTermMemory memory, Set<String> terms) {
    final haystack =
        '${memory.content} ${memory.title ?? ''}'.toLowerCase();
    var score = 0;
    for (final term in terms) {
      if (haystack.contains(term)) score += 2;
    }
    return score;
  }
}
