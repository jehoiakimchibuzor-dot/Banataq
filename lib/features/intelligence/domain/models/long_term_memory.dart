/// Category of a long-term memory entry.
enum MemoryEntryType { fact, preference, rule, knowledge, event }

/// A durable memory the brain persists across conversations.
///
/// Long-term memory is the part of the Intelligence Layer that survives app
/// restarts (via an offline-first persistent store) and is retrieved on every
/// turn so the model remembers the user's preferences, rules and facts.
class LongTermMemory {
  const LongTermMemory({
    required this.id,
    required this.type,
    required this.content,
    this.title,
    this.importance = 0.5,
    this.source,
    this.createdAt,
    this.lastAccessedAt,
    this.accessCount = 0,
    this.tags = const [],
  });

  final String id;
  final MemoryEntryType type;
  final String content;
  final String? title;

  /// 0.0 (trivial) to 1.0 (critical). Used for recall weighting.
  final double importance;

  /// Where the memory came from, e.g. `user` or `session-abc`.
  final String? source;

  final DateTime? createdAt;
  final DateTime? lastAccessedAt;
  final int accessCount;
  final List<String> tags;

  String get displayTitle => title ?? content;

  LongTermMemory copyWith({
    String? id,
    MemoryEntryType? type,
    String? content,
    String? title,
    double? importance,
    String? source,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? accessCount,
    List<String>? tags,
  }) {
    return LongTermMemory(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      title: title ?? this.title,
      importance: importance ?? this.importance,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      accessCount: accessCount ?? this.accessCount,
      tags: tags ?? this.tags,
    );
  }
}
