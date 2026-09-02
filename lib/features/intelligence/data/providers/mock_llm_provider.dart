import '../../domain/models/chat_usage.dart';
import '../../domain/models/intelligence_message.dart';
import '../../domain/models/llm_request.dart';
import '../../domain/models/llm_response.dart';
import '../../domain/models/llm_stream_event.dart';
import '../../domain/models/tool_call.dart';
import '../../domain/models/tool_definition.dart';
import '../../domain/providers/llm_provider.dart';
import '../../domain/providers/tokenizer.dart';
import 'simple_tokenizer.dart';

/// Fully deterministic, offline provider used for tests and as the safe
/// default. It never performs real inference.
///
/// Behaviour contract (kept intentionally scriptable so tests are stable):
/// * The response text is a fixed template that echoes the last user message.
/// * If a tool name appears as a substring of the last user message, the
///   provider requests that tool once (arguments = `{query: <last message>}`).
class MockLlmProvider implements LlmProvider {
  MockLlmProvider({this.seed = 'mock', Tokenizer? tokenizer})
      : tokenizer = tokenizer ?? const SimpleTokenizer();

  final String seed;
  final Tokenizer tokenizer;

  @override
  String get name => 'Mock';

  @override
  Set<LlmCapability> get capabilities => {
        LlmCapability.streaming,
        LlmCapability.toolCalls,
      };

  @override
  int get contextWindow => 8192;

  @override
  Future<LlmResponse> complete(LlmRequest request) async {
    final plan = _plan(request);
    final promptTokens = _countPromptTokens(request);
    final completionTokens = tokenizer.countTokens(plan.text);
    return LlmResponse(
      content: plan.text,
      toolCalls: plan.call == null ? const [] : [plan.call!],
      usage: ChatUsage(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
      ),
    );
  }

  @override
  Stream<LlmStreamEvent> stream(LlmRequest request) async* {
    final plan = _plan(request);
    const chunkSize = 8;
    for (var i = 0; i < plan.text.length; i += chunkSize) {
      final end = (i + chunkSize < plan.text.length)
          ? i + chunkSize
          : plan.text.length;
      yield LlmTextDelta(plan.text.substring(i, end));
    }
    if (plan.call != null) {
      yield LlmToolCallEvent(plan.call!);
    }
    yield LlmDoneEvent(
      ChatUsage(
        promptTokens: _countPromptTokens(request),
        completionTokens: tokenizer.countTokens(plan.text),
      ),
    );
  }

  _MockPlan _plan(LlmRequest request) {
    final lastUser = _lastUserMessage(request.messages);
    final tool = _matchingTool(request);
    final text = _respond(lastUser, tool?.name);

    if (tool == null) {
      return _MockPlan(text: text);
    }
    return _MockPlan(
      text: text,
      call: ToolCall(
        id: 'call-$seed-1',
        name: tool.name,
        arguments: {'query': lastUser},
      ),
    );
  }

  ToolDefinition? _matchingTool(LlmRequest request) {
    // A tool has already run this turn — do not request the same tool again,
    // otherwise the brain would loop forever on the same user message.
    if (request.messages.any((m) => m.role == IntelligenceRole.tool)) {
      return null;
    }
    final lastUser = _lastUserMessage(request.messages).toLowerCase();
    if (lastUser.isEmpty) return null;
    for (final tool in request.tools) {
      if (lastUser.contains(tool.name.toLowerCase())) {
        return tool;
      }
    }
    return null;
  }

  static String _lastUserMessage(List<IntelligenceMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == IntelligenceRole.user) {
        return messages[i].content;
      }
    }
    return '';
  }

  String _respond(String lastUser, String? toolName) {
    final subject = lastUser.isEmpty ? 'your request' : '"$lastUser"';
    final toolNote = toolName == null
        ? ''
        : '\nI will use the $toolName tool to handle this.';
    return 'Understood, you asked about $subject.$toolNote\n\n'
        'This is a deterministic mock answer from the $name provider '
        '(seed "$seed") generated entirely offline.';
  }

  int _countPromptTokens(LlmRequest request) {
    var total = tokenizer.countTokens(request.systemPrompt ?? '');
    for (final message in request.messages) {
      total += tokenizer.countTokens(message.content);
    }
    for (final tool in request.tools) {
      total += tokenizer.countTokens(tool.name + tool.description);
    }
    return total;
  }
}

class _MockPlan {
  const _MockPlan({required this.text, this.call});

  final String text;
  final ToolCall? call;
}
