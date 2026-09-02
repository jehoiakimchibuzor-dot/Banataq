import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/features/workspace/domain/models/workspace_memory.dart';
import 'package:banataq/features/workspace/presentation/workspace_controller.dart';
import 'package:banataq/features/workspace/services/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkspaceController buildController() {
    final controller = WorkspaceController(repository: MockWorkspaceRepository());
    addTearDown(controller.dispose);
    return controller;
  }

  group('WorkspaceSearch', () {
    test('empty query returns nothing', () {
      final results = MockWorkspaceService().search('');
      expect(results.isEmpty, isTrue);
    });

    test('finds matching sessions, tasks, files and memories', () {
      final results = MockWorkspaceService().search('supplier');

      expect(results.sessions, isNotEmpty);
      expect(results.tasks, isNotEmpty);
      expect(results.files, isNotEmpty);
      expect(results.total, greaterThan(0));
    });

    test('is case insensitive and partial', () {
      final upper = MockWorkspaceService().search('BUDGET').total;
      final lower = MockWorkspaceService().search('budget').total;
      expect(upper, greaterThan(0));
      expect(upper, lower);
    });

    test('no matches returns empty result set', () {
      final results = MockWorkspaceService().search('zzzz-not-present');
      expect(results.isEmpty, isTrue);
    });

    test('controller search updates searchResults after debounce', () async {
      final controller = buildController();
      await controller.initialLoad;

      expect(controller.searchResults.isEmpty, isTrue);

      await controller.search('admission');

      expect(controller.searchResults.isEmpty, isFalse);
      expect(controller.searchResults.tasks, isNotEmpty);
    });

    test('clearSearch resets results', () async {
      final controller = buildController();
      await controller.initialLoad;
      await controller.search('admission');

      controller.clearSearch();

      expect(controller.searchResults.isEmpty, isTrue);
      expect(controller.isSearching, isFalse);
    });

    test('controller adds a memory then search finds it', () async {
      final controller = buildController();
      await controller.initialLoad;

      controller.addMemory(
        'Payment terms',
        'Vendor invoices are due within 14 days.',
        MemoryCategory.rules,
      );
      await controller.search('invoices');

      expect(
        controller.searchResults.memories.any((m) => m.title == 'Payment terms'),
        isTrue,
      );
    });
  });
}
