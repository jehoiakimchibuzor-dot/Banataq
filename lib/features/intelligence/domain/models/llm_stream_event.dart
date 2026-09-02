import 'chat_usage.dart';
import 'tool_call.dart';

/// One event emitted by a streaming provider.
sealed class LlmStreamEvent {
  const LlmStreamEvent();
}

/// A chunk of generated text.
class LlmTextDelta extends LlmStreamEvent {
  const LlmTextDelta(this.text);

  final String text;
}

/// The model requested a tool call (may arrive after deltas).
class LlmToolCallEvent extends LlmStreamEvent {
  const LlmToolCallEvent(this.call);

  final ToolCall call;
}

/// The turn finished; carries final usage accounting.
class LlmDoneEvent extends LlmStreamEvent {
  const LlmDoneEvent(this.usage);

  final ChatUsage usage;
}
