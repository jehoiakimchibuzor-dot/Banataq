import 'package:banataq/core/design_system/design_system.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/features/workspace/domain/models/workspace_memory.dart';
import 'package:banataq/features/workspace/domain/models/workspace_timeline.dart';
import 'package:banataq/features/workspace/presentation/workspace_controller.dart';
import 'package:banataq/features/workspace/services/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WorkspaceController buildController() {
    final controller = WorkspaceController(repository: MockWorkspaceRepository());
    addTearDown(controller.dispose);
    return controller;
  }

  group('Files', () {
    test('loads seeded files through the repository', () {
      final service = MockWorkspaceService();
      final files = service.loadFiles();
      expect(files, isNotEmpty);
      expect(files.every((f) => f.id.isNotEmpty), isTrue);
    });

    test('addFile prepends and appears in overview', () async {
      final controller = buildController();
      await controller.initialLoad;

      final before = controller.files.length;
      controller.addFile('notes.md', AppFileType.document);

      expect(controller.files.length, before + 1);
      expect(controller.files.first.name, 'notes.md');
      expect(controller.overview.files, contains(controller.files.first));
    });

    test('deleteFile removes the file', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.files.first;
      controller.deleteFile(target);

      expect(controller.files.any((f) => f.id == target.id), isFalse);
    });

    test('toggleFileFavourite flips the flag', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.files.first;
      final before = target.favourite;
      controller.toggleFileFavourite(target);

      final updated = controller.files.firstWhere((f) => f.id == target.id);
      expect(updated.favourite, !before);
    });

    test('toggleFilePinned flips the flag', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.files.first;
      final before = target.pinned;
      controller.toggleFilePinned(target);

      final updated = controller.files.firstWhere((f) => f.id == target.id);
      expect(updated.pinned, !before);
    });

    test('summarizeFile attaches an AI summary', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.files.first;
      await controller.summarizeFile(target);

      final updated = controller.files.firstWhere((f) => f.id == target.id);
      expect(updated.summarized, isTrue);
      expect(updated.summary, isNotNull);
      expect(updated.summary!.length, greaterThan(10));
    });
  });

  group('Memory', () {
    test('loads seeded memories', () {
      final service = MockWorkspaceService();
      expect(service.loadMemories(), isNotEmpty);
    });

    test('addMemory inserts and updates overview', () async {
      final controller = buildController();
      await controller.initialLoad;

      final before = controller.memories.length;
      controller.addMemory(
        'Budget cap',
        'Keep the school budget under 200k.',
        MemoryCategory.goals,
      );

      expect(controller.memories.length, before + 1);
      expect(controller.memories.first.title, 'Budget cap');
      expect(controller.overview.memories, contains(controller.memories.first));
    });

    test('updateMemory edits title and content', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.memories.first;
      controller.updateMemory(
        target,
        title: 'Renamed',
        content: 'New content',
        category: MemoryCategory.rules,
      );

      final updated = controller.memories.firstWhere((m) => m.id == target.id);
      expect(updated.title, 'Renamed');
      expect(updated.content, 'New content');
      expect(updated.category, MemoryCategory.rules);
    });

    test('deleteMemory removes the entry', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.memories.first;
      controller.deleteMemory(target);

      expect(controller.memories.any((m) => m.id == target.id), isFalse);
    });

    test('toggleMemoryPinned flips the flag', () async {
      final controller = buildController();
      await controller.initialLoad;

      final target = controller.memories.first;
      final before = target.pinned;
      controller.toggleMemoryPinned(target);

      final updated = controller.memories.firstWhere((m) => m.id == target.id);
      expect(updated.pinned, !before);
    });
  });

  group('Timeline', () {
    test('loads seeded timeline ordered newest first', () {
      final service = MockWorkspaceService();
      final events = service.loadTimeline();
      expect(events, isNotEmpty);
      for (var i = 0; i < events.length - 1; i++) {
        expect(
          events[i].occurredAt.isBefore(events[i + 1].occurredAt),
          isFalse,
          reason: 'timeline should be newest first',
        );
      }
    });

    test('seed covers all event types', () {
      final events = MockWorkspaceService().loadTimeline();
      expect(
        events.any((e) => e.type == TimelineEventType.session),
        isTrue,
      );
      expect(events.any((e) => e.type == TimelineEventType.file), isTrue);
      expect(events.any((e) => e.type == TimelineEventType.memory), isTrue);
    });

    test('mutations append timeline events', () async {
      final controller = buildController();
      await controller.initialLoad;

      final before = controller.timeline.length;
      controller.addMemory('X', 'Y', MemoryCategory.context);
      controller.addFile('z.txt', AppFileType.document);

      expect(controller.timeline.length, greaterThanOrEqualTo(before + 2));
      expect(controller.timeline.first.type, TimelineEventType.file);
      expect(controller.timeline.first.description, 'z.txt');
    });
  });

  group('Briefing', () {
    test('regenerateBriefing cycles the briefing lines', () async {
      final controller = buildController();
      await controller.initialLoad;

      final first = controller.overview.briefing.map((l) => l.text).toList();
      controller.regenerateBriefing();

      final second = controller.overview.briefing.map((l) => l.text).toList();
      expect(second, isNot(equals(first)));
      expect(second, isNotEmpty);
    });
  });
}
