import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/features/workspace/domain/models/workspace.dart';
import 'package:banataq/features/workspace/domain/models/workspace_file.dart';
import 'package:banataq/features/workspace/domain/models/workspace_memory.dart';
import 'package:banataq/features/workspace/domain/models/workspace_session.dart';
import 'package:banataq/features/workspace/domain/models/workspace_task.dart';
import 'package:banataq/features/workspace/domain/models/workspace_timeline.dart';
import 'package:banataq/features/workspace/domain/services/briefing_deriver.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/core/design_system/design_system.dart';

Workspace _ws(String id, String name) => Workspace(
      id: id,
      name: name,
      description: '',
      emoji: '🗂️',
      accent: const Color(0xFFD4AF5A),
    );

WorkspaceTask _task(String id, String title, {bool done = false, DateTime? createdAt}) =>
    WorkspaceTask(id: id, title: title, done: done, createdAt: createdAt);

WorkspaceSession _session(String id, String title, DateTime updatedAt) => WorkspaceSession(
      id: id,
      title: title,
      updatedAt: updatedAt,
      createdAt: updatedAt,
    );

WorkspaceFile _file(String id, String name, DateTime? createdAt) => WorkspaceFile(
      id: id,
      name: name,
      type: AppFileType.pdf,
      createdAt: createdAt,
    );

WorkspaceMemory _memory(String id, String title, DateTime updatedAt) => WorkspaceMemory(
      id: id,
      title: title,
      content: 'content',
      category: MemoryCategory.context,
      updatedAt: updatedAt,
    );

TimelineEvent _event(String id, String title, DateTime at) => TimelineEvent(
      id: id,
      type: TimelineEventType.task,
      title: title,
      occurredAt: at,
    );

void main() {
  group('BriefingDeriver - empty workspace', () {
    test('empty workspace (no id, no data) → readiness briefing', () {
      final lines = BriefingDeriver.derive(
        workspace: const Workspace(id: '', name: '', description: '', emoji: '', accent: Color(0xFFD4AF5A)),
        tasks: const [],
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.length, 1);
      expect(lines.first.text, contains('Your workspace is ready'));
      expect(lines.first.icon, '✦');
    });

    test('workspace default but no signals → readiness', () {
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-default', 'My Workspace'),
        tasks: const [],
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.length, 1);
      expect(lines.first.text, contains('Your workspace is ready'));
    });

    test('workspace with only name but no items → readiness', () {
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'Test Workspace'),
        tasks: const [],
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.length, 1);
      expect(lines.first.text, contains('Your workspace is ready'));
    });
  });

  group('BriefingDeriver - task progress', () {
    test('task counts correct progress briefing', () {
      final tasks = [
        _task('t1', 'A', done: true),
        _task('t2', 'B', done: true),
        _task('t3', 'C', done: false),
        _task('t4', 'D', done: false),
        _task('t5', 'E', done: false),
      ];
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasks,
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.length, 1);
      expect(lines.first.text, contains('2 of 5 tasks done'));
      expect(lines.first.text, contains('3 tasks remaining'));
      expect(lines.first.highlight, isTrue);
      expect(lines.first.icon, '✓');
    });

    test('all tasks completed', () {
      final tasks = [_task('t1', 'A', done: true), _task('t2', 'B', done: true)];
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasks,
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.first.text, contains('All 2 tasks completed'));
      expect(lines.first.highlight, isTrue);
    });

    test('completed/reopened task → briefing changes', () {
      final tasksIncomplete = [_task('t1', 'A', done: false)];
      final lines1 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasksIncomplete,
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines1.first.text, contains('0 of 1 tasks done'));
      final tasksComplete = [_task('t1', 'A', done: true)];
      final lines2 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasksComplete,
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines2.first.text, contains('All 1 tasks completed'));
      expect(lines1.first.text, isNot(lines2.first.text));
    });

    test('single task pending text', () {
      final tasks = [_task('t1', 'A', done: false)];
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasks,
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.first.text, contains('1 task remaining'));
    });
  });

  group('BriefingDeriver - recent session', () {
    test('recent session reflects most recent by updatedAt (deterministic)', () {
      final now = DateTime.now();
      final older = _session('s1', 'Old Session', now.subtract(const Duration(hours: 5)));
      final newer = _session('s2', 'New Session', now);
      // Pass in reverse order (older first in list, newer second) and also test shuffled
      final lines1 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: [older, newer],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      final lines2 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: [newer, older],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines1.first.text, contains('New Session'));
      expect(lines2.first.text, contains('New Session'));
      expect(lines1.first.text, lines2.first.text); // deterministic regardless of input order
    });

    test('recent session title truncation and fallback', () {
      final now = DateTime.now();
      final sess = _session('s1', '', now);
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: [sess],
        files: const [],
        memories: const [],
        timeline: const [],
      );
      expect(lines.first.text, contains('Untitled session'));
    });
  });

  group('BriefingDeriver - recent file', () {
    test('recent file reflects most recent by createdAt', () {
      final now = DateTime.now();
      final older = _file('f1', 'old.pdf', now.subtract(const Duration(days: 1)));
      final newer = _file('f2', 'new.pdf', now);
      final lines1 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: const [],
        files: [older, newer],
        memories: const [],
        timeline: const [],
      );
      final lines2 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: const [],
        files: [newer, older],
        memories: const [],
        timeline: const [],
      );
      expect(lines1.first.text, contains('new.pdf'));
      expect(lines1.first.text, lines2.first.text);
    });

    test('file with empty name fallback', () {
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: const [],
        files: [_file('f1', '', DateTime.now())],
        memories: const [],
        timeline: const [],
      );
      expect(lines.first.text, contains('file'));
    });
  });

  group('BriefingDeriver - memories', () {
    test('single memory → neutral count, not Memory saved: title', () {
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: const [],
        files: const [],
        memories: [_memory('m1', 'My Title', DateTime.now())],
        timeline: const [],
      );
      expect(lines.length, 1);
      expect(lines.first.text, '1 memory saved');
      expect(lines.first.text, isNot(contains('Memory saved: My Title')));
      expect(lines.first.icon, '🧠');
    });

    test('multiple memories count is neutral and based on persisted state', () {
      final now = DateTime.now();
      final mems = [
        _memory('m1', 'A', now.subtract(const Duration(hours: 3))),
        _memory('m2', 'B', now.subtract(const Duration(hours: 2))),
        _memory('m3', 'C', now),
      ];
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: const [],
        files: const [],
        memories: mems,
        timeline: const [],
      );
      expect(lines.first.text, '3 memories saved');
    });

    test('memory wording does not depend on title existence', () {
      final lines1 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: const [],
        sessions: const [],
        files: const [],
        memories: [_memory('m1', '', DateTime.now())],
        timeline: const [],
      );
      expect(lines1.first.text, '1 memory saved');
    });
  });

  group('BriefingDeriver - multiple signals → max 4 lines', () {
    test('multiple signals produce 1-4 lines, deterministic order tasks→session→file→memory', () {
      final now = DateTime.now();
      final tasks = [_task('t1', 'A', done: false), _task('t2', 'B', done: true)];
      final sessions = [_session('s1', 'S1', now), _session('s2', 'S2', now.subtract(const Duration(hours: 1)))];
      final files = [_file('f1', 'a.pdf', now), _file('f2', 'b.pdf', now.subtract(const Duration(hours: 2)))];
      final memories = [_memory('m1', 'M1', now), _memory('m2', 'M2', now)];
      final timeline = [_event('tl1', 'Timeline event', now)];
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasks,
        sessions: sessions,
        files: files,
        memories: memories,
        timeline: timeline,
      );
      expect(lines.length, lessThanOrEqualTo(4));
      expect(lines.length, greaterThanOrEqualTo(1));
      // Order should be tasks, session, file, memory (timeline fallback not needed when memories exist)
      expect(lines[0].text, contains('tasks done'));
      expect(lines[1].text, contains('Recent session'));
      expect(lines[2].text, contains('Latest file'));
      expect(lines[3].text, contains('memories saved'));
    });

    test('timeline fallback when no memories', () {
      final now = DateTime.now();
      final lines = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: [_task('t1', 'A', done: false)],
        sessions: const [],
        files: const [],
        memories: const [],
        timeline: [_event('tl1', 'File added', now)],
      );
      expect(lines.length, 2);
      expect(lines[1].text, 'File added');
    });
  });

  group('BriefingDeriver - deterministic output', () {
    test('same state shuffled input → same briefing', () {
      final now = DateTime.now();
      final tasksA = [_task('t1', 'A', done: false), _task('t2', 'B', done: true)];
      final tasksB = [_task('t2', 'B', done: true), _task('t1', 'A', done: false)];
      final sessionsA = [_session('s1', 'Old', now.subtract(const Duration(hours: 2))), _session('s2', 'New', now)];
      final sessionsB = [_session('s2', 'New', now), _session('s1', 'Old', now.subtract(const Duration(hours: 2)))];
      final filesA = [_file('f1', 'a.pdf', now.subtract(const Duration(hours: 1))), _file('f2', 'b.pdf', now)];
      final filesB = [_file('f2', 'b.pdf', now), _file('f1', 'a.pdf', now.subtract(const Duration(hours: 1)))];
      final lines1 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasksA,
        sessions: sessionsA,
        files: filesA,
        memories: const [],
        timeline: const [],
      );
      final lines2 = BriefingDeriver.derive(
        workspace: _ws('ws-1', 'WS'),
        tasks: tasksB,
        sessions: sessionsB,
        files: filesB,
        memories: const [],
        timeline: const [],
      );
      expect(lines1.map((l) => l.text).toList(), lines2.map((l) => l.text).toList());
      expect(lines1.map((l) => l.icon).toList(), lines2.map((l) => l.icon).toList());
    });
  });

  group('BriefingDeriver - production integration via FirestoreWorkspaceRepository', () {
    test('task mutation → derived briefing updates', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      var overview = repo.loadOverview();
      expect(overview.briefing.first.text, contains('Your workspace is ready'));
      repo.addTasks([WorkspaceTask(id: 't1', title: 'Task 1', done: false)]);
      overview = repo.loadOverview();
      expect(overview.briefing.any((l) => l.text.contains('1 tasks done') || l.text.contains('0 of 1')), isTrue);
      expect(overview.briefing.first.text, isNot(contains('Your workspace is ready')));
    });

    test('file mutation → derived briefing updates', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      var overview = repo.loadOverview();
      expect(overview.briefing.first.text, contains('Your workspace is ready'));
      repo.addFile('doc.pdf', AppFileType.pdf);
      overview = repo.loadOverview();
      expect(overview.briefing.any((l) => l.text.contains('Latest file: doc.pdf')), isTrue);
    });

    test('session mutation → derived briefing updates', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      var overview = repo.loadOverview();
      expect(overview.briefing.first.text, contains('Your workspace is ready'));
      repo.createSession('My Session');
      overview = repo.loadOverview();
      expect(overview.briefing.any((l) => l.text.contains('My Session')), isTrue);
    });

    test('memory mutation → derived briefing updates', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      var overview = repo.loadOverview();
      expect(overview.briefing.first.text, contains('Your workspace is ready'));
      repo.addMemory('Title', 'Content', MemoryCategory.goals);
      overview = repo.loadOverview();
      expect(overview.briefing.any((l) => l.text.contains('memory saved')), isTrue);
      expect(overview.briefing.any((l) => l.text.contains('Your workspace is ready')), isFalse);
    });

    test('Firestore loadOverview does not source briefing from _fallback mock data', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      // Add real data so derived briefing is not mock's static "You worked here yesterday..."
      repo.addTasks([WorkspaceTask(id: 't1', title: 'Real Task', done: false)]);
      final overview = repo.loadOverview();
      // Mock's static briefing contains "You worked here yesterday" — derived should not
      expect(overview.briefing.any((l) => l.text.contains('You worked here yesterday')), isFalse);
      expect(overview.briefing.any((l) => l.text.contains('Real Task')), isFalse); // title not in briefing, count is
      expect(overview.briefing.any((l) => l.text.contains('tasks done')), isTrue);
    });

    test('regenerateBriefing same state → same briefing', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      repo.addTasks([WorkspaceTask(id: 't1', title: 'A', done: false)]);
      final first = repo.regenerateBriefing();
      final second = repo.regenerateBriefing();
      expect(first.map((l) => l.text).toList(), second.map((l) => l.text).toList());
    });

    test('regenerateBriefing changed state → changed briefing', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      repo.addTasks([WorkspaceTask(id: 't1', title: 'A', done: false)]);
      final before = repo.regenerateBriefing();
      repo.addTasks([WorkspaceTask(id: 't2', title: 'B', done: false)]);
      final after = repo.regenerateBriefing();
      expect(before.map((l) => l.text).toList(), isNot(after.map((l) => l.text).toList()));
    });

    test('regenerateBriefing for Firestore does not cycle mock variants', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1', 'WS')]);
      final first = repo.regenerateBriefing();
      final second = repo.regenerateBriefing();
      // Both should be derived readiness, not mock variant "Focus on the supplier..." or "Three open tasks..."
      expect(first.first.text, contains('Your workspace is ready'));
      expect(second.first.text, contains('Your workspace is ready'));
      expect(first.first.text, second.first.text);
      // Ensure not cycling mock variants
      expect(first.any((l) => l.text.contains('Focus on the supplier')), isFalse);
      expect(first.any((l) => l.text.contains('Three open tasks')), isFalse);
    });
  });
}
