import 'dart:math' as math;

import '../../domain/providers/embedding_generator.dart';

/// Deterministic, offline hashing bag-of-words embedding.
///
/// Each token is hashed into one of [dimensions] bins; the vector is L2
/// normalised so cosine similarity reduces to a dot product. Two texts sharing
/// vocabulary land close together, which is exactly what offline RAG needs.
class HashingEmbeddingGenerator implements EmbeddingGenerator {
  const HashingEmbeddingGenerator({this.dimensions = 256});

  @override
  final int dimensions;

  @override
  List<double> embed(String text) {
    final vector = List<double>.filled(dimensions, 0);
    final tokens = text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty);
    for (final token in tokens) {
      var hash = 0;
      for (final unit in token.codeUnits) {
        hash = (hash * 31 + unit) & 0x7fffffff;
      }
      vector[hash % dimensions] += 1.0;
    }

    var norm = 0.0;
    for (final value in vector) {
      norm += value * value;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }
}
