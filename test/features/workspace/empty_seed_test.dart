import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/features/workspace/services/workspace_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('empty runtime workspace (seed: false)', () {
    test('loads a fully empty workspace', () {
      final service = MockWorkspaceService(seed: false);

      expect(service.loadSessions(), isEmpty);
      expect(service.loadTasks(), isEmpty);
      expect(service.loadFiles(), isEmpty);
      expect(service.loadMemories(), isEmpty);
      expect(service.loadTimeline(), isEmpty);
      expect(service.search('supplier').isEmpty, isTrue);
    });

    test('uses neutral metadata, briefing and no suggestions', () {
      final repository =
          MockWorkspaceRepository(service: MockWorkspaceService(seed: false));
      final overview = repository.loadOverview();

      expect(overview.workspace.name, 'My Workspace');
      expect(overview.workspace.description, isEmpty);
      expect(overview.briefing, isNotEmpty);
      expect(overview.suggestions, isEmpty);
      expect(overview.continueTitle, isNull);
    });

    test('new session starts with a usable empty conversation', () {
      final service = MockWorkspaceService(seed: false);
      final detail = service.createSession('Plan the exam preparation');

      expect(detail.session.title, 'Plan the exam preparation');
      expect(detail.messages, isEmpty);
      expect(detail.session.messageCount, 0);
      expect(detail.aiSummary, isNull);
      expect(detail.actionItems, isEmpty);
      expect(detail.keyFacts, isEmpty);
    });

    test('Ollama-backed brain receives the empty workspace', () async {
      final repository =
          MockWorkspaceRepository(service: MockWorkspaceService(seed: false));
      final adapter = WorkspaceKnowledgeAdapter(repository);

      expect(adapter.buildDocuments(), isEmpty);
      expect(adapter.buildBriefing(), contains('0 files'));

      final engine = await WorkspaceBrainFactory.build(repository: repository);
      expect(await engine.rag.chunkCount, 0);
    });
  });
}
