import '../models/long_term_memory.dart';

/// Persistent, queryable long-term memory.
///
/// Implementation is offline-first (in-memory plus SharedPreferences), so the
/// brain keeps working with no network and survives restarts.
abstract interface class MemoryStore {
  Future<List<LongTermMemory>> all();

  Future<void> add(LongTermMemory memory);

  Future<void> addAll(List<LongTermMemory> memories);

  Future<LongTermMemory?> get(String id);

  Future<void> delete(String id);

  /// Best-effort relevance search over memory content.
  Future<List<LongTermMemory>> search(String query, {int limit = 10});

  Future<List<LongTermMemory>> recent({int limit = 10});

  Future<List<LongTermMemory>> important({int limit = 10});

  /// Records that a memory was recalled (bumps access count / recency).
  Future<void> touch(String id);
}
