/// A nearest-neighbour hit returned by a [VectorStore].
class VectorMatch {
  const VectorMatch({
    required this.id,
    required this.score,
    this.metadata = const {},
  });

  final String id;

  /// Cosine similarity, 1.0 being identical.
  final double score;

  final Map<String, dynamic> metadata;
}
