import '../models/vector_match.dart';

/// Approximate-nearest-neighbour store for embeddings.
///
/// The reference implementation is an in-memory cosine store; a production
/// build can swap in Hive/SQLite or a remote vector database.
abstract interface class VectorStore {
  int get length;

  Future<void> upsert(
    String id,
    List<double> vector, {
    Map<String, dynamic> metadata = const {},
  });

  Future<List<VectorMatch>> search(
    List<double> query, {
    int limit = 5,
    double minScore = 0.0,
  });

  Future<void> remove(String id);

  Future<void> clear();
}
