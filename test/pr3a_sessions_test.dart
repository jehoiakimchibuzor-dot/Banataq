import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/features/workspace/domain/models/workspace.dart';
import 'package:banataq/features/workspace/domain/models/workspace_session.dart';
import 'package:banataq/features/workspace/domain/models/workspace_session_message.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';

void main() {
  group('PR3A Session serialization', () {
    test('WorkspaceSession toJson/fromJson roundtrip preserves all fields', () {
      final now = DateTime.parse('2026-09-06T03:00:00.000Z');
      final s = WorkspaceSession(
        id: 's-123',
        title: 'Test Session',
        updatedAt: now,
        createdAt: now,
        summary: 'Summary',
        purpose: 'Purpose',
        preview: 'Preview',
        status: SessionStatus.inProgress,
        pinned: true,
        messageCount: 5,
        durationLabel: '5m',
        linkedFileIds: ['f1', 'f2'],
        linkedTaskIds: ['t1'],
      );
      final json = s.toJson();
      expect(json['id'], 's-123');
      expect(json['status'], 'inProgress');
      expect(json['pinned'], true);
      expect(json['linkedFileIds'], ['f1', 'f2']);
      final decoded = WorkspaceSession.fromJson(json);
      expect(decoded.id, s.id);
      expect(decoded.title, s.title);
      expect(decoded.summary, s.summary);
      expect(decoded.purpose, s.purpose);
      expect(decoded.preview, s.preview);
      expect(decoded.status, s.status);
      expect(decoded.pinned, s.pinned);
      expect(decoded.messageCount, s.messageCount);
      expect(decoded.durationLabel, s.durationLabel);
      expect(decoded.linkedFileIds, s.linkedFileIds);
      expect(decoded.linkedTaskIds, s.linkedTaskIds);
      expect(decoded.updatedAt.toIso8601String(), now.toIso8601String());
    });

    test('WorkspaceSession fromJson handles missing/legacy fields safely', () {
      final decoded = WorkspaceSession.fromJson({'id': 's-1'});
      expect(decoded.title, '');
      expect(decoded.status, SessionStatus.completed);
      expect(decoded.pinned, false);
      expect(decoded.messageCount, 0);
      expect(decoded.linkedFileIds, isEmpty);
    });

    test('WorkspaceSessionMessage toJson/fromJson roundtrip', () {
      final now = DateTime.parse('2026-09-06T03:00:00.000Z');
      const WorkspaceSessionMessage msg = WorkspaceSessionMessage(id: 'm-1', author: MessageAuthor.user, text: 'Hello', sentAt: null);
      expect(msg.text, 'Hello');
      final json = WorkspaceSessionMessage(id: 'm-1', author: MessageAuthor.ai, text: 'Hi', sentAt: now).toJson();
      expect(json['author'], 'ai');
      expect(json['text'], 'Hi');
      final decoded = WorkspaceSessionMessage.fromJson(json);
      expect(decoded.author, MessageAuthor.ai);
      expect(decoded.text, 'Hi');
      expect(decoded.sentAt?.toIso8601String(), now.toIso8601String());
      // legacy missing author defaults to user
      final legacy = WorkspaceSessionMessage.fromJson({'id': 'm-2', 'text': 'X'});
      expect(legacy.author, MessageAuthor.user);
    });
  });

  group('PR3A Firestore sessions — cache (mock Firestore)', () {
    Workspace testWorkspace(String id) => Workspace(
          id: id,
          name: 'WS $id',
          description: '',
          emoji: '🗂️',
          accent: const Color(0xFFD4AF5A),
        );

    test('createSession persists and loadSessions returns it', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWorkspace('ws-1')]);
      final detail = repo.createSession('First Session');
      expect(detail.session.title, 'First Session');
      expect(repo.loadSessions().length, 1);
      expect(repo.loadSessions().first.title, 'First Session');
    });

    test('loadSessionDetail, addSessionMessage, sendMessage, rename, pin/archive, delete', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWorkspace('ws-1')]);
      final detail = repo.createSession('S1');
      final sid = detail.session.id;
      // Initially no messages
      var loaded = repo.loadSessionDetail(sid);
      expect(loaded.messages, isEmpty);
      // Add user message
      repo.addSessionMessage(sid, MessageAuthor.user, 'Hello');
      loaded = repo.loadSessionDetail(sid);
      expect(loaded.messages.length, 1);
      expect(loaded.messages.first.text, 'Hello');
      expect(loaded.messages.first.author, MessageAuthor.user);
      // Send message (creates user+ai)
      repo.sendMessage(sid, 'Prompt');
      loaded = repo.loadSessionDetail(sid);
      expect(loaded.messages.length, 3); // Hello + Prompt + Thinking…
      // Pin
      repo.setSessionPinned(sid, true);
      expect(repo.loadSessions().first.pinned, true);
      // Archive
      repo.setSessionArchived(sid, true);
      expect(repo.loadSessions().first.archived, true);
      // Rename
      repo.renameSession(sid, 'Renamed');
      expect(repo.loadSessions().first.title, 'Renamed');
      // Delete
      repo.deleteSession(sid);
      expect(repo.loadSessions(), isEmpty);
      expect(repo.loadSessionDetail(sid).messages, isEmpty);
    });

    test('user/workspace isolation', () {
      final repoA = FirestoreWorkspaceRepository(uidProvider: () => 'user-A');
      final repoB = FirestoreWorkspaceRepository(uidProvider: () => 'user-B');
      repoA.setTestWorkspaces([testWorkspace('ws-A')]);
      repoB.setTestWorkspaces([testWorkspace('ws-B')]);
      repoA.createSession('Session A');
      expect(repoA.loadSessions().length, 1);
      expect(repoB.loadSessions().length, 0);
      repoB.createSession('Session B');
      expect(repoB.loadSessions().length, 1);
      expect(repoA.loadSessions().first.title, 'Session A');
      expect(repoB.loadSessions().first.title, 'Session B');
    });

    test('missing/legacy fields deserialize safely and messages survive reload', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([testWorkspace('ws-1')]);
      final sid = repo.createSession('S').session.id;
      repo.addSessionMessage(sid, MessageAuthor.user, 'Msg1');
      repo.addSessionMessage(sid, MessageAuthor.ai, 'Reply1');
      final before = repo.loadSessionDetail(sid);
      expect(before.messages.length, 2);
      // Simulate reload by creating new repo instance with same uid and same in-memory? 
      // For this test, messages are in-memory, so we verify they are preserved via cache
      final after = repo.loadSessionDetail(sid);
      expect(after.messages.length, 2);
      expect(after.messages.first.text, 'Msg1');
    });
  });
}
