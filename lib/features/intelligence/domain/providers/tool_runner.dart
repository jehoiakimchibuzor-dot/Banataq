import '../models/tool_call.dart';
import '../models/tool_definition.dart';
import '../models/tool_result.dart';

/// Executes a tool call against the registered implementation.
typedef ToolExecutor = Future<String> Function(ToolCall call);

/// Registry + executor for the tool-calling framework.
///
/// Tools are *defined* as schema (sent to the model) and *registered* as
/// behaviour (run locally). Registration is intentionally in-memory: the set
/// of available tools is fixed per process.
abstract interface class ToolRunner {
  void register(ToolDefinition definition, ToolExecutor executor);

  List<ToolDefinition> get definitions;

  bool isRegistered(String name);

  /// Runs every call, capturing per-call success or failure.
  Future<List<ToolResult>> executeAll(List<ToolCall> calls);
}
