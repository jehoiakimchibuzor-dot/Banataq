/// Outcome of executing one [ToolCall].
class ToolResult {
  const ToolResult({
    required this.toolCallId,
    required this.name,
    required this.content,
    this.isError = false,
  });

  final String toolCallId;
  final String name;
  final String content;
  final bool isError;

  /// Renders as the content of a `role: tool` message fed back to the model.
  String asToolMessage() => isError ? 'ERROR: $content' : content;
}
