import '../models/llm_request.dart';
import '../models/llm_response.dart';
import '../models/llm_stream_event.dart';

/// Capabilities a provider advertises so the brain can pick code paths.
enum LlmCapability { streaming, toolCalls }

/// Abstraction over any LLM backend (mock, local, OpenAI, Gemini, ...).
///
/// Providers translate the neutral [LlmRequest]/[LlmResponse] types into their
/// own wire format. The brain never knows which provider it is talking to.
abstract interface class LlmProvider {
  String get name;

  Set<LlmCapability> get capabilities;

  /// Maximum input tokens the model accepts in one turn.
  int get contextWindow;

  Future<LlmResponse> complete(LlmRequest request);

  /// Emits text deltas and, optionally, tool-call events as they arrive.
  Stream<LlmStreamEvent> stream(LlmRequest request);
}
