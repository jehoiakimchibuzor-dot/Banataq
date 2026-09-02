import 'intelligence_message.dart';
import 'tool_definition.dart';

/// A fully-formed request for the [LlmProvider].
class LlmRequest {
  const LlmRequest({
    this.systemPrompt,
    required this.messages,
    this.tools = const [],
    this.temperature = 0.7,
    this.maxTokens = 2000,
  });

  /// Optional system instructions prepended by the provider.
  final String? systemPrompt;

  /// Conversation messages (user/assistant/tool) after the system prompt.
  final List<IntelligenceMessage> messages;

  /// Tools the model may call during this turn.
  final List<ToolDefinition> tools;

  final double temperature;
  final int maxTokens;
}
