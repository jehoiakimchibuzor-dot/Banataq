import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolRunnerImpl', () {
    test('registers and lists definitions', () {
      final runner = ToolRunnerImpl();
      runner.register(
        const ToolDefinition(name: 'a', description: 'Does a'),
        (_) async => 'a-ok',
      );
      runner.register(
        const ToolDefinition(name: 'b', description: 'Does b'),
        (_) async => 'b-ok',
      );
      expect(runner.definitions.map((d) => d.name), ['a', 'b']);
      expect(runner.isRegistered('a'), isTrue);
      expect(runner.isRegistered('zz'), isFalse);
    });

    test('executeAll runs every call in order', () async {
      final runner = ToolRunnerImpl();
      runner.register(
        const ToolDefinition(name: 'a', description: ''),
        (call) async => 'got ${call.arguments['x']}',
      );
      final results = await runner.executeAll([
        ToolCall(id: '1', name: 'a', arguments: {'x': 'one'}),
        ToolCall(id: '2', name: 'a', arguments: {'x': 'two'}),
      ]);
      expect(results, hasLength(2));
      expect(results[0].content, 'got one');
      expect(results[1].content, 'got two');
      expect(results.every((r) => !r.isError), isTrue);
    });

    test('unregistered tool reports an error result', () async {
      final runner = ToolRunnerImpl();
      final results = await runner.executeAll([
        const ToolCall(id: '1', name: 'missing', arguments: {}),
      ]);
      expect(results.single.isError, isTrue);
      expect(results.single.content, contains('not registered'));
    });

    test('throwing executor produces an error result', () async {
      final runner = ToolRunnerImpl();
      runner.register(
        const ToolDefinition(name: 'boom', description: ''),
        (_) async => throw StateError('kaboom'),
      );
      final results = await runner.executeAll([
        const ToolCall(id: '1', name: 'boom', arguments: {}),
      ]);
      expect(results.single.isError, isTrue);
      expect(results.single.content, contains('kaboom'));
    });

    test('re-registering a name replaces its executor', () async {
      final runner = ToolRunnerImpl();
      runner.register(
        const ToolDefinition(name: 'a', description: 'v1'),
        (_) async => 'first',
      );
      runner.register(
        const ToolDefinition(name: 'a', description: 'v2'),
        (_) async => 'second',
      );
      final results = await runner.executeAll([
        const ToolCall(id: '1', name: 'a', arguments: {}),
      ]);
      expect(results.single.content, 'second');
      expect(runner.definitions, hasLength(1));
    });
  });
}
