import '../../domain/models/vector_match.dart';
import '../../domain/providers/vector_store.dart';

/// Reference vector store: brute-force cosine search over an in-memory list.
///
/// Fine for workspace-scale corpora; swap for a real ANN index in production.
class InMemoryVectorStore implements VectorStore {
  final List<_VectorEntry> _entries = [];

  @override
  int get length => _entries.length;

  @override
  Future<void> upsert(
    String id,
    List<double> vector, {
    Map<String, dynamic> metadata = const {},
  }) async {
    _entries.removeWhere((e) => e.id == id);
    _entries.add(
      _VectorEntry(id: id, vector: List.of(vector), metadata: metadata),
    );
  }

  @override
  Future<List<VectorMatch>> search(
    List<double> query, {
    int limit = 5,
    double minScore = 0.0,
  }) async {
    final scored = <_Scored>[
      for (final entry in _entries)
        _Scored(
          id: entry.id,
          score: _cosine(query, entry.vector),
          metadata: entry.metadata,
        ),
    ]..sort((a, b) => b.score.compareTo(a.score));

    return scored
        .where((s) => s.score >= minScore)
        .take(limit)
        .map(
          (s) => VectorMatch(id: s.id, score: s.score, metadata: s.metadata),
        )
        .toList();
  }

  @override
  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  static double _cosine(List<double> a, List<double> b) {
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }
}

class _VectorEntry {
  _VectorEntry({
    required this.id,
    required this.vector,
    required this.metadata,
  });

  final String id;
  final List<double> vector;
  final Map<String, dynamic> metadata;
}

class _Scored {
  _Scored({
    required this.id,
    required this.score,
    required this.metadata,
  });

  final String id;
  final double score;
  final Map<String, dynamic> metadata;
}
