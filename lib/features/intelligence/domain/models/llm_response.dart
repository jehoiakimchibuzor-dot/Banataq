import 'chat_usage.dart';
import 'tool_call.dart';

/// A completed model turn: final text plus any tool calls the model wants.
class LlmResponse {
  const LlmResponse({
    this.content = '',
    this.toolCalls = const [],
    this.usage = ChatUsage.empty,
  });

  final String content;
  final List<ToolCall> toolCalls;
  final ChatUsage usage;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}
