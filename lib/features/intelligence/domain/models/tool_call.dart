/// A request from the model to execute one tool.
class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  @override
  bool operator ==(Object other) =>
      other is ToolCall &&
      other.id == id &&
      other.name == name &&
      _deepEquals(other.arguments, arguments);

  @override
  int get hashCode => Object.hash(id, name, arguments);
}

bool _deepEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    final other = b[entry.key];
    if (other is Map<String, dynamic> && entry.value is Map<String, dynamic>) {
      if (!_deepEquals(other, entry.value as Map<String, dynamic>)) {
        return false;
      }
    } else if (other != entry.value) {
      return false;
    }
  }
  return true;
}
