import '../models/long_term_memory.dart';

/// Extracts candidate long-term memories from a user message.
///
/// The offline implementation is pattern-based; a hosted model could replace
/// it with a real extraction pass. The brain calls it after each turn.
abstract interface class MemoryExtractor {
  List<LongTermMemory> extract(String text);
}
