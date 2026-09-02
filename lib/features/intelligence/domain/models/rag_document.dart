/// A source document that can be indexed by the RAG engine.
class RagDocument {
  const RagDocument({
    required this.id,
    required this.title,
    required this.content,
    this.source,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;

  /// Where the document came from, e.g. `file`, `memory`, `session`, `timeline`.
  final String? source;

  final DateTime? createdAt;
}
