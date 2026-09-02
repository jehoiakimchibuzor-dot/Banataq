import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const embeddings = HashingEmbeddingGenerator();

  double cosine(List<double> a, List<double> b) {
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  test('produces fixed-size vectors', () {
    expect(embeddings.dimensions, 256);
    expect(embeddings.embed('hello world').length, 256);
  });

  test('is deterministic for the same text', () {
    expect(embeddings.embed('banataq'), embeddings.embed('banataq'));
  });

  test('similar texts are closer than dissimilar texts', () {
    final query = embeddings.embed('school budget meeting');
    final similar = embeddings.embed('school budget for the school');
    final unrelated = embeddings.embed('market vegetables pricing');
    expect(cosine(query, similar), greaterThan(cosine(query, unrelated)));
  });

  test('empty text embeds to the zero vector (no NaN)', () {
    final vector = embeddings.embed('');
    expect(vector, hasLength(256));
    expect(vector.any((v) => v.isNaN), isFalse);
  });
}
