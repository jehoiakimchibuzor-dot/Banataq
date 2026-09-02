import '../domain/models/long_term_memory.dart';
import '../domain/providers/memory_extractor.dart';

/// Pattern-based memory extraction for offline operation.
///
/// Detects explicit memory statements ("remember that ..."), preferences
/// ("I prefer ...") and rules ("always/never ...") and converts them into
/// durable [LongTermMemory] entries.
class SimpleMemoryExtractor implements MemoryExtractor {
  const SimpleMemoryExtractor();

  @override
  List<LongTermMemory> extract(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];

    final memories = <LongTermMemory>[];

    final fact = RegExp(
      r'remember(?: that)? ([^.!?\n]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (fact != null) {
      final content = fact.group(1)!.trim();
      memories.add(_memory(MemoryEntryType.fact, content, 'user'));
    }

    final preference = RegExp(
      r'(?:i prefer|i like|i love|i want) ([^.!?\n]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (preference != null) {
      final content = preference.group(1)!.trim();
      memories.add(_memory(MemoryEntryType.preference, content, 'user'));
    }

    final rule = RegExp(
      r'(?:always|never|must always|must never) ([^.!?\n]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (rule != null) {
      final content = rule.group(1)!.trim();
      memories.add(_memory(MemoryEntryType.rule, content, 'user'));
    }

    return memories;
  }

  static LongTermMemory _memory(
    MemoryEntryType type,
    String content,
    String source,
  ) {
    final cleaned = _slug(content);
    return LongTermMemory(
      id: 'mem-$type.name-$cleaned',
      type: type,
      content: content,
      title: content.length > 40 ? '${content.substring(0, 40)}...' : content,
      importance: type == MemoryEntryType.rule ? 0.8 : 0.6,
      source: source,
      createdAt: DateTime.now(),
    );
  }

  static String _slug(String content) {
    final sanitized =
        content.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final max = sanitized.length > 28 ? 28 : sanitized.length;
    return sanitized.substring(0, max);
  }
}
