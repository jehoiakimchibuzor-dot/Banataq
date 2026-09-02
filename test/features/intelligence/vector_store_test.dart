import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('upsert replaces an existing id', () async {
    final store = InMemoryVectorStore();
    await store.upsert('a', const [1, 0]);
    await store.upsert('a', const [0, 1], metadata: {'v': 2});

    expect(store.length, 1);
    final matches = await store.search(const [0, 1]);
    expect(matches, hasLength(1));
    expect(matches.first.metadata['v'], 2);
  });

  test('search ranks by cosine similarity and honours the limit', () async {
    final store = InMemoryVectorStore();
    await store.upsert('exact', const [1, 0]);
    await store.upsert('half', const [0.5, 0.5]);
    await store.upsert('orthogonal', const [0, 1]);

    final matches = await store.search(const [1, 0], limit: 2);
    expect(matches, hasLength(2));
    expect(matches.first.id, 'exact');
    expect(matches.first.score, closeTo(1.0, 0.001));
    expect(matches[1].id, 'half');
  });

  test('minScore filters low-similarity results', () async {
    final store = InMemoryVectorStore();
    await store.upsert('high', const [1, 0]);
    await store.upsert('low', const [0, 1]);

    final matches = await store.search(const [1, 0], minScore: 0.5);
    expect(matches.map((m) => m.id), ['high']);
  });

  test('remove and clear', () async {
    final store = InMemoryVectorStore();
    await store.upsert('a', const [1, 0]);
    await store.upsert('b', const [0, 1]);

    await store.remove('a');
    expect(store.length, 1);

    await store.clear();
    expect(store.length, 0);
  });
}
