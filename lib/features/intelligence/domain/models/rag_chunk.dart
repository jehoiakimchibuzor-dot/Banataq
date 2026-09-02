/// A retrieved slice of an indexed [RagDocument].
class RagChunk {
  const RagChunk({
    required this.id,
    required this.documentId,
    required this.title,
    required this.text,
    required this.chunkIndex,
    this.score = 1.0,
  });

  final String id;
  final String documentId;
  final String title;
  final String text;
  final int chunkIndex;

  /// Similarity score returned by the vector store (1.0 = exact match).
  final double score;
}
