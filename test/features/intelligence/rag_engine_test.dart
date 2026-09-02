import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RagEngine buildEngine() => RagEngine(
        embeddings: const HashingEmbeddingGenerator(),
        store: InMemoryVectorStore(),
        tokenizer: const SimpleTokenizer(),
        chunkSize: 20,
        chunkOverlap: 4,
      );

  const document = RagDocument(
    id: 'doc-1',
    title: 'Supplier quotes',
    content:
        'The Gano school is comparing three suppliers for chalk and exercise '
        'books. Abubakar Traders quoted the lowest price for bulk orders. '
        'The delivery window is two weeks.',
    source: 'file',
  );

  test('index creates retrievable chunks', () async {
    final rag = buildEngine();
    await rag.index(document);

    expect(await rag.chunkCount, greaterThan(0));
    final hits = await rag.retrieve('chalk and exercise books price');
    expect(hits, isNotEmpty);
    expect(hits.first.documentId, 'doc-1');
    expect(hits.first.title, 'Supplier quotes');
  });

  test('retrieval is ranked — exact terms score higher', () async {
    final rag = buildEngine();
    await rag.index(document);
    await rag.index(
      const RagDocument(
        id: 'doc-2',
        title: 'Gardening tips',
        content: 'Water the tomatoes every evening during the dry season.',
        source: 'file',
      ),
    );

    final hits = await rag.retrieve('bulk orders for chalk', limit: 2);
    expect(hits.first.documentId, 'doc-1');
  });

  test('unrelated query returns little or nothing', () async {
    final rag = buildEngine();
    await rag.index(document);
    final hits = await rag.retrieve('zanzibar violin tuning', limit: 5);
    expect(hits, isEmpty);
  });

  test('removeDocument drops every chunk of a document', () async {
    final rag = buildEngine();
    await rag.index(document);
    final before = await rag.chunkCount;
    expect(before, greaterThan(0));

    await rag.removeDocument('doc-1');
    expect(await rag.chunkCount, 0);
    expect(await rag.retrieve('chalk'), isEmpty);
  });

  test('clear empties the store', () async {
    final rag = buildEngine();
    await rag.index(document);
    await rag.clear();
    expect(await rag.chunkCount, 0);
  });
}
