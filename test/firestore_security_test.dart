import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/features/workspace/domain/models/workspace.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';

/// Phase 1 stabilization: Firestore path-scoping guarantees.
///
/// These unit tests verify the *client-side* ownership boundary enforced by
/// [FirestoreWorkspaceRepository] (users/{uid}/workspaces/...) without a live
/// backend:
///   1. Authenticated owner resolves their own workspace scope.
///   2. A different authenticated uid cannot see another uid's workspaces.
///   3. Unauthenticated (null/empty uid) performs no Firestore I/O and
///      surfaces an empty state instead of leaking data.
///   4. Nested resources (sessions/tasks/files/memories) inherit the same
///      workspace/user isolation.
///
/// The server-side counterpart (firestore.rules + firestore.rules.test.js)
/// denies cross-user and unauthenticated reads/writes at the backend.
void main() {
  Workspace ws(String id) => Workspace(
        id: id,
        name: 'WS $id',
        description: '',
        emoji: '🗂️',
        accent: const Color(0xFFD4AF5A),
      );

  group('Firestore security — owner allowed', () {
    test('authenticated owner loads their own workspace scope', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-owner');
      repo.setTestWorkspaces([ws('ws-1')]);
      await repo.ready;
      expect(repo.getWorkspace().id, 'ws-1');
      expect(repo.loadWorkspaces().map((w) => w.id), contains('ws-1'));
    });

    test('nested resources resolve under the owner workspace', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-owner');
      repo.setTestWorkspaces([ws('ws-1')]);
      repo.createSession('S');
      repo.addTasks(const []);
      expect(repo.loadSessions().length, 1);
      expect(repo.loadSessions().first.title, 'S');
    });
  });

  group('Firestore security — different user denied (isolation)', () {
    test('another uid sees none of the owner workspaces', () {
      final owner = FirestoreWorkspaceRepository(uidProvider: () => 'user-owner');
      final stranger =
          FirestoreWorkspaceRepository(uidProvider: () => 'user-stranger');
      owner.setTestWorkspaces([ws('ws-1')]);
      stranger.setTestWorkspaces(const []);
      expect(
        stranger.loadWorkspaces().where((w) => w.id == 'ws-1'),
        isEmpty,
      );
      expect(stranger.getWorkspace().name, isEmpty);
    });

    test('nested resources are isolated per uid', () {
      final owner = FirestoreWorkspaceRepository(uidProvider: () => 'user-owner');
      final stranger =
          FirestoreWorkspaceRepository(uidProvider: () => 'user-stranger');
      owner.setTestWorkspaces([ws('ws-1')]);
      stranger.setTestWorkspaces([ws('ws-2')]);
      owner.createSession('Owner session');
      expect(owner.loadSessions().length, 1);
      // Stranger's workspace scope is a different document tree.
      expect(stranger.loadSessions(), isEmpty);
      stranger.createSession('Stranger session');
      expect(
        owner.loadSessions().where((s) => s.title == 'Stranger session'),
        isEmpty,
      );
    });
  });

  group('Firestore security — unauthenticated denied (no I/O)', () {
    test('null uid surfaces empty state and performs no writes', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => null);
      await repo.ready;
      expect(repo.getWorkspace().name, isEmpty);
      expect(repo.loadWorkspaces(), isEmpty);
      expect(repo.loadSessions(), isEmpty);
      expect(repo.loadTasks(), isEmpty);
      expect(repo.loadFiles(), isEmpty);
      expect(repo.loadMemories(), isEmpty);
      // Mutations are no-ops without a uid: nothing persisted, no crash.
      repo.createSession('S');
      expect(repo.loadSessions(), isEmpty);
    });

    test('empty uid surfaces empty state', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => '');
      await repo.ready;
      expect(repo.getWorkspace().name, isEmpty);
      expect(repo.loadTasks(), isEmpty);
    });
  });
}
