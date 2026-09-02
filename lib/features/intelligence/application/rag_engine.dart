import '../domain/models/rag_chunk.dart';
import '../domain/models/rag_document.dart';
import '../domain/providers/embedding_generator.dart';
import '../domain/providers/tokenizer.dart';
import '../domain/providers/vector_store.dart';

/// Retrieval-Augmented Generation engine.
///
/// Indexes [RagDocument]s into overlapping chunks, embeds each chunk with the
/// configured [EmbeddingGenerator] and stores it in a [VectorStore]. Retrieval
/// embeds the query and returns the nearest chunks with scores, so downstream
/// code (the brain) can cite sources.
class RagEngine {
  RagEngine({
    required this.embeddings,
    required this.store,
    required this.tokenizer,
    this.chunkSize = 512,
    this.chunkOverlap = 64,
  });

  final EmbeddingGenerator embeddings;
  final VectorStore store;
  final Tokenizer tokenizer;
  final int chunkSize;
  final int chunkOverlap;

  Future<void> index(RagDocument document) async {
    final chunks = _chunk(document.content);
    for (var i = 0; i < chunks.length; i++) {
      final chunkId = '${document.id}#$i';
      await store.upsert(
        chunkId,
        embeddings.embed(chunks[i]),
        metadata: {
          'documentId': document.id,
          'title': document.title,
          'text': chunks[i],
          'chunkIndex': i,
          'source': document.source,
        },
      );
    }
  }

  Future<List<RagChunk>> retrieve(
    String query, {
    int limit = 5,
    double minScore = 0.05,
  }) async {
    final matches = await store.search(
      embeddings.embed(query),
      limit: limit,
      minScore: minScore,
    );
    return [
      for (final match in matches)
        RagChunk(
          id: match.id,
          documentId: match.metadata['documentId']?.toString() ?? match.id,
          title: match.metadata['title']?.toString() ?? '',
          text: match.metadata['text']?.toString() ?? '',
          chunkIndex: (match.metadata['chunkIndex'] as num?)?.toInt() ?? 0,
          score: match.score,
        ),
    ];
  }

  Future<void> removeDocument(String documentId) async {
    final matches = await store.search(
      List<double>.filled(embeddings.dimensions, 0),
      limit: store.length,
      minScore: -1,
    );
    for (final match in matches) {
      if (match.metadata['documentId'] == documentId) {
        await store.remove(match.id);
      }
    }
  }

  Future<void> clear() => store.clear();

  Future<int> get chunkCount async => store.length;

  /// Splits content into token-sized chunks with overlap. Paragraph-aligned
  /// where possible so chunks stay readable.
  List<String> _chunk(String content) {
    final paragraphs = content
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) return const [];

    final chunks = <String>[];
    var buffer = StringBuffer();
    var bufferTokens = 0;
    final overlapTokens = <String>[];

    void flush() {
      if (buffer.isEmpty) return;
      final text = buffer.toString();
      chunks.add(text);
      final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
      overlapTokens
        ..clear()
        ..addAll(words);
      buffer = StringBuffer();
      bufferTokens = 0;
    }

    for (final paragraph in paragraphs) {
      final paragraphTokens = tokenizer.countTokens(paragraph);
      if (bufferTokens + paragraphTokens > chunkSize) {
        flush();
        if (overlapTokens.length > 1) {
          final overlapText = overlapTokens
              .take(chunkOverlap)
              .join(' ');
          buffer.write(overlapText);
          bufferTokens = tokenizer.countTokens(overlapText);
        }
      }
      buffer.write(buffer.isEmpty ? paragraph : '\n\n$paragraph');
      bufferTokens += paragraphTokens;
    }
    flush();
    return chunks;
  }
}
