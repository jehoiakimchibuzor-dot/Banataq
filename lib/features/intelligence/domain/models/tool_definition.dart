/// Static, serializable description of a tool the model may invoke.
///
/// The executable behaviour lives in the `ToolRunner` registry (keyed by
/// [name]); this class is only the schema sent to the model so the provider
/// can advertise available functions.
class ToolDefinition {
  const ToolDefinition({
    required this.name,
    required this.description,
    this.parameters = const {},
  });

  final String name;
  final String description;

  /// JSON Schema describing the arguments.
  final Map<String, dynamic> parameters;
}
