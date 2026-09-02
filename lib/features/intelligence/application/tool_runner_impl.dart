import '../domain/models/tool_call.dart';
import '../domain/models/tool_definition.dart';
import '../domain/models/tool_result.dart';
import '../domain/providers/tool_runner.dart';

/// Default [ToolRunner]: a name-keyed registry of tool implementations.
class ToolRunnerImpl implements ToolRunner {
  final List<ToolDefinition> _definitions = [];
  final Map<String, ToolExecutor> _executors = {};

  @override
  void register(ToolDefinition definition, ToolExecutor executor) {
    _executors[definition.name] = executor;
    _definitions.removeWhere((d) => d.name == definition.name);
    _definitions.add(definition);
  }

  @override
  List<ToolDefinition> get definitions => List.unmodifiable(_definitions);

  @override
  bool isRegistered(String name) => _executors.containsKey(name);

  @override
  Future<List<ToolResult>> executeAll(List<ToolCall> calls) async {
    final results = <ToolResult>[];
    for (final call in calls) {
      final executor = _executors[call.name];
      if (executor == null) {
        results.add(
          ToolResult(
            toolCallId: call.id,
            name: call.name,
            content: 'Tool not registered: ${call.name}',
            isError: true,
          ),
        );
        continue;
      }
      try {
        final output = await executor(call);
        results.add(
          ToolResult(toolCallId: call.id, name: call.name, content: output),
        );
      } catch (error) {
        results.add(
          ToolResult(
            toolCallId: call.id,
            name: call.name,
            content: 'Error: $error',
            isError: true,
          ),
        );
      }
    }
    return results;
  }
}
