/// Produces a fixed-size vector for a piece of text.
///
/// The offline implementation is a hashing bag-of-words; a remote provider
/// could swap in real model embeddings without touching the RAG pipeline.
abstract interface class EmbeddingGenerator {
  int get dimensions;

  List<double> embed(String text);
}
