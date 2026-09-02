/// Role of a single message in an LLM conversation.
enum IntelligenceRole { system, user, assistant, tool }

/// One message in a conversation, independent of any provider's wire format.
///
/// Tool messages carry a [toolCallId] that links them to the `ToolCall` that
/// produced them, mirroring the OpenAI-style tool loop.
class IntelligenceMessage {
  const IntelligenceMessage({
    required this.role,
    this.content = '',
    this.name,
    this.toolCallId,
  });

  final IntelligenceRole role;
  final String content;

  /// Optional speaker name (used for assistant tool-call messages).
  final String? name;

  /// Identifier of the `ToolCall` this message is answering (role `tool`).
  final String? toolCallId;

  bool get isToolResult => role == IntelligenceRole.tool;

  @override
  bool operator ==(Object other) =>
      other is IntelligenceMessage &&
      other.role == role &&
      other.content == content &&
      other.name == name &&
      other.toolCallId == toolCallId;

  @override
  int get hashCode => Object.hash(role, content, name, toolCallId);

  @override
  String toString() =>
      'IntelligenceMessage(${role.name}, toolCallId: $toolCallId)';
}
