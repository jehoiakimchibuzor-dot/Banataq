import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/features/workspace/domain/models/workspace.dart';
import 'package:banataq/features/workspace/domain/models/workspace_memory.dart';
import 'package:banataq/features/workspace/domain/models/workspace_session_message.dart';
import 'package:banataq/features/workspace/domain/models/workspace_task.dart';
import 'package:banataq/features/workspace/domain/models/workspace_timeline.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/core/design_system/design_system.dart';

void main() {
  Workspace testWs(String id) => Workspace(
        id: id,
        name: 'WS $id',
        description: '',
        emoji: '🗂️',
        accent: const Color(0xFFD4AF5A),
      );

  group('PR3D Timeline serialization', () {
    test('TimelineEvent toJson/fromJson roundtrip preserves all fields', () {
      final now = DateTime.parse('2026-09-10T12:00:00.000Z');
      final event = TimelineEvent(
        id: 'tl-1',
        type: TimelineEventType.task,
        title: 'Task added',
        description: 'My task',
        occurredAt: now,
        refId: 't-1',
      );
      final json = event.toJson();
      expect(json['id'], 'tl-1');
      expect(json['type'], 'task');
      expect(json['title'], 'Task added');
      expect(json['description'], 'My task');
      expect(json['refId'], 't-1');
      expect(json['occurredAt'], isA<Timestamp>());
      // Timestamp stores UTC instant; compare via milliseconds to avoid local TZ offset
      expect((json['occurredAt'] as Timestamp).toDate().millisecondsSinceEpoch, now.millisecondsSinceEpoch);

      final decoded = TimelineEvent.fromJson(json);
      expect(decoded.id, event.id);
      expect(decoded.type, event.type);
      expect(decoded.title, event.title);
      expect(decoded.description, event.description);
      expect(decoded.refId, event.refId);
      expect(decoded.occurredAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromJson handles Timestamp occurredAt', () {
      final now = DateTime.parse('2026-09-10T10:00:00.000Z');
      final json = {
        'id': 'tl-2',
        'type': 'file',
        'title': 'File added',
        'occurredAt': Timestamp.fromDate(now),
      };
      final decoded = TimelineEvent.fromJson(json);
      expect(decoded.type, TimelineEventType.file);
      expect(decoded.occurredAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromJson handles String occurredAt', () {
      final now = DateTime.parse('2026-09-10T10:00:00.000Z');
      final json = {
        'id': 'tl-3',
        'type': 'memory',
        'title': 'Memory saved',
        'occurredAt': now.toIso8601String(),
      };
      final decoded = TimelineEvent.fromJson(json);
      expect(decoded.occurredAt.toIso8601String(), now.toIso8601String());
    });

    test('fromJson handles DateTime occurredAt', () {
      final now = DateTime.now();
      final json = {
        'id': 'tl-4',
        'type': 'session',
        'title': 'Chat started',
        'occurredAt': now,
      };
      final decoded = TimelineEvent.fromJson(json);
      expect(decoded.occurredAt.toIso8601String(), now.toIso8601String());
    });

    test('fromJson handles int milliseconds occurredAt', () {
      final now = DateTime.parse('2026-09-10T10:00:00.000Z');
      final json = {
        'id': 'tl-5',
        'type': 'milestone',
        'title': 'Task completed',
        'occurredAt': now.millisecondsSinceEpoch,
      };
      final decoded = TimelineEvent.fromJson(json);
      expect(decoded.occurredAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromJson handles missing/invalid type safely', () {
      final json1 = {'id': 'tl-6', 'title': 'X'};
      final d1 = TimelineEvent.fromJson(json1);
      expect(d1.type, TimelineEventType.session);
      expect(d1.title, 'X');
      final json2 = {'id': 'tl-7', 'type': 'unknown_type', 'title': 'Y', 'occurredAt': DateTime.now().toIso8601String()};
      final d2 = TimelineEvent.fromJson(json2);
      expect(d2.type, TimelineEventType.session);
    });

    test('fromJson handles missing title/description/refId', () {
      final json = {'id': 'tl-8', 'type': 'file', 'occurredAt': DateTime.now().toIso8601String()};
      final d = TimelineEvent.fromJson(json);
      expect(d.title, '');
      expect(d.description, isNull);
      expect(d.refId, isNull);
      expect(d.id, 'tl-8');
    });

    test('fromJson handles null occurredAt with fallback to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final json = {'id': 'tl-9', 'type': 'memory', 'title': 'T', 'occurredAt': null};
      final d = TimelineEvent.fromJson(json);
      expect(d.occurredAt.isAfter(before), isTrue);
    });

    test('copyWith creates updated copy', () {
      final now = DateTime.now();
      final e = TimelineEvent(id: 'tl-1', type: TimelineEventType.task, title: 'T', occurredAt: now);
      final copy = e.copyWith(title: 'New', type: TimelineEventType.file, description: 'desc');
      expect(copy.id, 'tl-1');
      expect(copy.title, 'New');
      expect(copy.type, TimelineEventType.file);
      expect(copy.description, 'desc');
      expect(copy.occurredAt, now);
    });

    test('all TimelineEventType values roundtrip', () {
      for (final type in TimelineEventType.values) {
        final e = TimelineEvent(id: 'tl-${type.name}', type: type, title: 'T', occurredAt: DateTime.now());
        final json = e.toJson();
        expect(json['type'], type.name);
        final decoded = TimelineEvent.fromJson(json);
        expect(decoded.type, type);
      }
    });
  });

  group('PR3D Firestore Timeline — cache', () {
    test('empty workspace loadTimeline isEmpty', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      expect(repo.loadTimeline(), isEmpty);
    });

    test('empty workspace with no workspaces returns empty', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces(const []);
      expect(repo.loadTimeline(), isEmpty);
    });

    test('createSession persists timeline Chat started', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      expect(repo.loadTimeline(), isEmpty);
      final detail = repo.createSession('My Session');
      final tl = repo.loadTimeline();
      expect(tl.length, 1);
      expect(tl.first.type, TimelineEventType.session);
      expect(tl.first.title, 'Chat started');
      expect(tl.first.description, 'My Session');
      expect(tl.first.refId, detail.session.id);
    });

    test('sendMessage persists New message timeline', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      final sid = repo.createSession('S').session.id;
      // Clear timeline to isolate sendMessage effect
      // createSession already added 1 event, so clear for test
      final before = repo.loadTimeline().length;
      repo.sendMessage(sid, 'Hello prompt');
      final tl = repo.loadTimeline();
      expect(tl.length, before + 1);
      expect(tl.first.type, TimelineEventType.session);
      expect(tl.first.title, 'New message');
      expect(tl.first.description, 'Hello prompt');
      expect(tl.first.refId, sid);
    });

    test('addSessionMessage user adds timeline, ai does not', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      final sid = repo.createSession('S').session.id;
      final before = repo.loadTimeline().length;
      repo.addSessionMessage(sid, MessageAuthor.user, 'User text');
      expect(repo.loadTimeline().length, before + 1);
      expect(repo.loadTimeline().first.description, 'User text');
      final before2 = repo.loadTimeline().length;
      repo.addSessionMessage(sid, MessageAuthor.ai, 'AI text');
      expect(repo.loadTimeline().length, before2); // ai should not add timeline
    });

    test('setTaskDone adds milestone/task timeline', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addTasks([WorkspaceTask(id: 't-1', title: 'Task A', done: false)]);
      final before = repo.loadTimeline().length;
      repo.setTaskDone('t-1', true);
      var tl = repo.loadTimeline();
      expect(tl.length, before + 1);
      expect(tl.first.type, TimelineEventType.milestone);
      expect(tl.first.title, 'Task completed');
      expect(tl.first.description, 'Task A');
      repo.setTaskDone('t-1', false);
      tl = repo.loadTimeline();
      expect(tl.first.type, TimelineEventType.task);
      expect(tl.first.title, 'Task reopened');
    });

    test('addTasks adds Task added per task', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      final before = repo.loadTimeline().length;
      repo.addTasks([
        WorkspaceTask(id: 't-1', title: 'A', done: false),
        WorkspaceTask(id: 't-2', title: 'B', done: false),
      ]);
      final tl = repo.loadTimeline();
      expect(tl.length, before + 2);
      // Newest first: last added task should be first timeline event? Check that both exist
      expect(tl.where((e) => e.title == 'Task added').length, 2);
      expect(tl.map((e) => e.description), containsAll(['A', 'B']));
    });

    test('addFile adds File added timeline', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      final before = repo.loadTimeline().length;
      final files = repo.addFile('doc.pdf', AppFileType.pdf);
      final id = files.first.id;
      final tl = repo.loadTimeline();
      expect(tl.length, before + 1);
      expect(tl.first.type, TimelineEventType.file);
      expect(tl.first.title, 'File added');
      expect(tl.first.description, 'doc.pdf');
      expect(tl.first.refId, id);
    });

    test('summarizeFile adds File summarized timeline', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      final id = repo.addFile('a.pdf', AppFileType.pdf).first.id;
      final before = repo.loadTimeline().length;
      repo.summarizeFile(id);
      final tl = repo.loadTimeline();
      expect(tl.length, before + 1);
      expect(tl.first.title, 'File summarized');
      expect(tl.first.description, 'a.pdf');
      expect(tl.first.refId, id);
    });

    test('addMemory adds Memory saved timeline', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      final before = repo.loadTimeline().length;
      final mems = repo.addMemory('Title', 'Content', MemoryCategory.goals);
      final id = mems.first.id;
      final tl = repo.loadTimeline();
      expect(tl.length, before + 1);
      expect(tl.first.type, TimelineEventType.memory);
      expect(tl.first.title, 'Memory saved');
      expect(tl.first.description, 'Title');
      expect(tl.first.refId, id);
    });

    test('timeline is newest-first ordered by occurredAt', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      // Create events with explicit delays to ensure ordering
      repo.addMemory('First', 'C', MemoryCategory.context);
      await Future.delayed(const Duration(milliseconds: 10));
      repo.addFile('second.pdf', AppFileType.pdf);
      await Future.delayed(const Duration(milliseconds: 10));
      repo.addMemory('Third', 'C', MemoryCategory.goals);
      final tl = repo.loadTimeline();
      expect(tl.length, 3);
      // Newest should be Third
      expect(tl[0].description, 'Third');
      expect(tl[1].description, 'second.pdf');
      expect(tl[2].description, 'First');
      // Verify descending occurredAt
      for (int i = 0; i < tl.length - 1; i++) {
        expect(tl[i].occurredAt.isAfter(tl[i + 1].occurredAt) || tl[i].occurredAt.isAtSameMomentAs(tl[i + 1].occurredAt), isTrue,
            reason: 'timeline should be newest first');
      }
    });

    test('user/workspace isolation', () {
      final repoA = FirestoreWorkspaceRepository(uidProvider: () => 'user-A');
      final repoB = FirestoreWorkspaceRepository(uidProvider: () => 'user-B');
      repoA.setTestWorkspaces([testWs('ws-A')]);
      repoB.setTestWorkspaces([testWs('ws-B')]);
      repoA.addMemory('A', 'C', MemoryCategory.context);
      expect(repoA.loadTimeline().length, 1);
      expect(repoB.loadTimeline().length, 0);
      repoB.addFile('b.pdf', AppFileType.pdf);
      expect(repoB.loadTimeline().length, 1);
      expect(repoA.loadTimeline().first.description, 'A');
      expect(repoB.loadTimeline().first.description, 'b.pdf');
      expect(repoA.loadTimeline().where((e) => e.description == 'b.pdf'), isEmpty);
    });

    test('unauthenticated mutations do not create timeline', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => null);
      repo.setTestWorkspaces([testWs('ws-1')]);
      // Even with workspace set, null uid should be unauthenticated and not persist timeline
      // setTestWorkspaces with null uidProvider still allows workspace but mutations guard _isUnauthenticated
      // Create a new repo with null uid to test guard
      final unauth = FirestoreWorkspaceRepository(uidProvider: () => '');
      unauth.setTestWorkspaces([testWs('ws-1')]);
      expect(unauth.loadTimeline(), isEmpty);
      unauth.addMemory('T', 'C', MemoryCategory.context);
      expect(unauth.loadTimeline(), isEmpty);
      unauth.addFile('f.pdf', AppFileType.pdf);
      expect(unauth.loadTimeline(), isEmpty);
      unauth.createSession('S');
      expect(unauth.loadTimeline(), isEmpty);
    });

    test('timeline survives reload via cache and respects empty workspace', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addMemory('Persist', 'C', MemoryCategory.context);
      expect(repo.loadTimeline().length, 1);
      expect(repo.loadTimeline().first.description, 'Persist');
      // Reset to empty workspace should clear timeline
      repo.setTestWorkspaces(const []);
      expect(repo.loadTimeline(), isEmpty);
      // New workspace again starts empty
      repo.setTestWorkspaces([testWs('ws-2')]);
      expect(repo.loadTimeline(), isEmpty);
    });

    test('timeline events have stable IDs and are newest-first after multiple mutations', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWs('ws-1')]);
      repo.addMemory('M1', 'C', MemoryCategory.context);
      final firstId = repo.loadTimeline().first.id;
      repo.addFile('f1.pdf', AppFileType.pdf);
      final secondId = repo.loadTimeline().first.id;
      expect(firstId, isNot(secondId));
      expect(repo.loadTimeline().length, 2);
      expect(repo.loadTimeline().first.id, secondId);
      expect(repo.loadTimeline().last.id, firstId);
    });
  });
}
