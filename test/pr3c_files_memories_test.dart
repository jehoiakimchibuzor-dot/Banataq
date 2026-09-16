import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/core/design_system/components/cards/file_card.dart';
import 'package:banataq/features/workspace/domain/models/workspace.dart';
import 'package:banataq/features/workspace/domain/models/workspace_file.dart';
import 'package:banataq/features/workspace/domain/models/workspace_memory.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';

void main() {
  Workspace testWs(String id) => Workspace(id: id, name: 'WS $id', description: '', emoji: '🗂️', accent: const Color(0xFFD4AF5A));

  group('PR3C File serialization', () {
    test('WorkspaceFile toJson/fromJson roundtrip', () {
      final now = DateTime.parse('2026-09-06T10:00:00.000Z');
      const WorkspaceFile file = WorkspaceFile(id: 'f1', name: 'doc.pdf', type: AppFileType.pdf, meta: '10 KB', summarized: true, summary: 'Sum', createdAt: null);
      expect(file.name, 'doc.pdf');
      final json = WorkspaceFile(id: 'f1', name: 'doc.pdf', type: AppFileType.pdf, meta: '10 KB', summarized: true, summary: 'Sum', createdAt: now, favourite: true, pinned: false, tags: ['a']).toJson();
      expect(json['type'], 'pdf');
      expect(json['summarized'], true);
      final decoded = WorkspaceFile.fromJson(json);
      expect(decoded.id, 'f1');
      expect(decoded.name, 'doc.pdf');
      expect(decoded.type, AppFileType.pdf);
      expect(decoded.summarized, true);
      expect(decoded.favourite, true);
      expect(decoded.tags, ['a']);
      expect(decoded.createdAt?.toIso8601String(), now.toIso8601String());
    });

    test('legacy/missing fields deserialize safely', () {
      final decoded = WorkspaceFile.fromJson({'id': 'f1', 'name': 'x'});
      expect(decoded.type, AppFileType.unknown);
      expect(decoded.summarized, false);
      expect(decoded.favourite, false);
      expect(decoded.tags, isEmpty);
    });
  });

  group('PR3C Memory serialization', () {
    test('WorkspaceMemory toJson/fromJson roundtrip', () {
      final now = DateTime.parse('2026-09-06T10:00:00.000Z');
      final mem = WorkspaceMemory(id: 'm1', title: 'T', content: 'C', category: MemoryCategory.goals, source: 'src', confidence: MemoryConfidence.confirmed, pinned: true, updatedAt: now);
      final json = mem.toJson();
      expect(json['category'], 'goals');
      expect(json['confidence'], 'confirmed');
      final decoded = WorkspaceMemory.fromJson(json);
      expect(decoded.id, 'm1');
      expect(decoded.category, MemoryCategory.goals);
      expect(decoded.confidence, MemoryConfidence.confirmed);
      expect(decoded.pinned, true);
      expect(decoded.updatedAt?.toIso8601String(), now.toIso8601String());
    });

    test('legacy/missing fields deserialize safely', () {
      final decoded = WorkspaceMemory.fromJson({'id': 'm1', 'title': 'T', 'content': 'C'});
      expect(decoded.category, MemoryCategory.context);
      expect(decoded.confidence, MemoryConfidence.confirmed);
      expect(decoded.pinned, false);
    });
  });

  group('PR3C Firestore Files — cache', () {
    test('create/add file persists and loadFiles retrieves', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      expect(repo.loadFiles(), isEmpty);
      repo.addFile('doc.pdf', AppFileType.pdf);
      expect(repo.loadFiles().length, 1);
      expect(repo.loadFiles().first.name, 'doc.pdf');
      expect(repo.loadFiles().first.type, AppFileType.pdf);
    });

    test('update file favourite/pinned and delete', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addFile('a.pdf', AppFileType.pdf);
      final id = repo.loadFiles().first.id;
      repo.setFileFavourite(id, true);
      expect(repo.loadFiles().first.favourite, true);
      repo.setFilePinned(id, true);
      expect(repo.loadFiles().first.pinned, true);
      repo.deleteFile(id);
      expect(repo.loadFiles(), isEmpty);
    });

    test('summarizeFile', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addFile('doc.pdf', AppFileType.pdf);
      final id = repo.loadFiles().first.id;
      final summarized = repo.summarizeFile(id);
      expect(summarized.summarized, true);
      expect(summarized.summary, contains('doc.pdf'));
      expect(repo.loadFiles().first.summarized, true);
    });

    test('user/workspace isolation for files', () {
      final repoA = FirestoreWorkspaceRepository(uidProvider: () => 'user-A');
      final repoB = FirestoreWorkspaceRepository(uidProvider: () => 'user-B');
      repoA.setTestWorkspaces([testWs('ws-A')]);
      repoB.setTestWorkspaces([testWs('ws-B')]);
      repoA.addFile('a.pdf', AppFileType.pdf);
      expect(repoA.loadFiles().length, 1);
      expect(repoB.loadFiles().length, 0);
      repoB.addFile('b.pdf', AppFileType.pdf);
      expect(repoB.loadFiles().length, 1);
      expect(repoA.loadFiles().first.name, 'a.pdf');
    });

    test('files survive reload via cache', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addFile('persist.pdf', AppFileType.pdf);
      expect(repo.loadFiles().length, 1);
      expect(repo.loadFiles().first.name, 'persist.pdf');
    });
  });

  group('PR3C Firestore Memories — cache', () {
    test('create/add memory persists and loadMemories retrieves', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      expect(repo.loadMemories(), isEmpty);
      repo.addMemory('Title', 'Content', MemoryCategory.goals);
      expect(repo.loadMemories().length, 1);
      expect(repo.loadMemories().first.title, 'Title');
    });

    test('update/delete/pin memory', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addMemory('T', 'C', MemoryCategory.context);
      final id = repo.loadMemories().first.id;
      repo.updateMemory(id, title: 'NewT');
      expect(repo.loadMemories().first.title, 'NewT');
      repo.setMemoryPinned(id, true);
      expect(repo.loadMemories().first.pinned, true);
      repo.deleteMemory(id);
      expect(repo.loadMemories(), isEmpty);
    });

    test('user/workspace isolation for memories', () {
      final repoA = FirestoreWorkspaceRepository(uidProvider: () => 'user-A');
      final repoB = FirestoreWorkspaceRepository(uidProvider: () => 'user-B');
      repoA.setTestWorkspaces([testWs('ws-A')]);
      repoB.setTestWorkspaces([testWs('ws-B')]);
      repoA.addMemory('A', 'C', MemoryCategory.context);
      expect(repoA.loadMemories().length, 1);
      expect(repoB.loadMemories().length, 0);
      repoB.addMemory('B', 'C', MemoryCategory.goals);
      expect(repoB.loadMemories().first.title, 'B');
      expect(repoA.loadMemories().first.title, 'A');
    });

    test('memories survive reload via cache', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addMemory('Persist', 'Content', MemoryCategory.context);
      expect(repo.loadMemories().length, 1);
      expect(repo.loadMemories().first.title, 'Persist');
    });
  });
}
