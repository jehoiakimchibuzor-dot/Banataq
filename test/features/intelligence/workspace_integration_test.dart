import 'package:banataq/features/intelligence/intelligence.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adapter builds documents from workspace content', () {
    final adapter = WorkspaceKnowledgeAdapter(MockWorkspaceRepository());
    final documents = adapter.buildDocuments();

    expect(documents, isNotEmpty);
    final sources = documents.map((d) => d.source).toSet();
    expect(sources, contains('file'));
    expect(sources, contains('memory'));
    expect(sources, contains('session'));
    expect(sources, contains('timeline'));
  });

  test('adapter briefing summarises the knowledge base', () {
    final adapter = WorkspaceKnowledgeAdapter(MockWorkspaceRepository());
    final briefing = adapter.buildBriefing();
    expect(briefing, contains('files'));
    expect(briefing, contains('memories'));
  });

  test('WorkspaceBrainFactory indexes workspace and registers tools', () async {
    final engine = await WorkspaceBrainFactory.build(
      repository: MockWorkspaceRepository(),
    );

    expect(await engine.rag.chunkCount, greaterThan(0));
    final toolNames = engine.toolRunner.definitions.map((d) => d.name);
    expect(toolNames, contains('search_workspace'));
    expect(toolNames, contains('list_files'));
    expect(toolNames, contains('get_memories'));
    expect(toolNames, contains('complete_task'));
    expect(toolNames, contains('summarize_file'));
    expect(toolNames, contains('workspace_briefing'));
  });

  test('workspace brain grounds answers with indexed files', () async {
    final engine = await WorkspaceBrainFactory.build(
      repository: MockWorkspaceRepository(),
    );

    final reply = await engine.brain.chat(
      conversationId: 'w1',
      userMessage: 'suppliers quote',
    );

    expect(reply.sources, isNotEmpty);
    expect(
      reply.sources.any((s) => s.title.toLowerCase().contains('supplier')),
      isTrue,
    );
  });

  test('workspace tools can act on the repository', () async {
    final engine = await WorkspaceBrainFactory.build(
      repository: MockWorkspaceRepository(),
    );

    final reply = await engine.brain.chat(
      conversationId: 'w2',
      userMessage: 'use search_workspace to find anything about admission',
    );

    expect(reply.toolResults, hasLength(1));
    expect(reply.toolResults.single.isError, isFalse);
    expect(reply.text, isNotEmpty);
  });

  test('summarize_file tool mutates the workspace', () async {
    final repository = MockWorkspaceRepository();
    final engine = await WorkspaceBrainFactory.build(repository: repository);
    final target = repository.loadFiles().first;

    final reply = await engine.brain.chat(
      conversationId: 'w3',
      userMessage: 'summarize_file ${target.id}',
    );

    expect(reply.toolResults, hasLength(1));
    expect(reply.toolResults.single.isError, isFalse);
    final updated = repository.loadFiles().firstWhere((f) => f.id == target.id);
    expect(updated.summarized, isTrue);
  });
}
