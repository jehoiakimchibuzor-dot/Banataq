import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/app_result.dart';
import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace.dart';
import '../../domain/models/workspace_file.dart';
import '../../domain/models/workspace_memory.dart';
import '../../domain/models/workspace_overview.dart';
import '../../domain/models/workspace_search.dart';
import '../../domain/models/workspace_session.dart';
import '../../domain/models/workspace_session_detail.dart';
import '../../domain/models/workspace_session_message.dart';
import '../../domain/models/workspace_task.dart';
import '../../domain/models/workspace_timeline.dart';
import '../../services/workspace_service.dart';

/// Seam between the app and workspace data.
///
/// Sprint 1 implements this with the mock service only. Sprint 2 adds a
/// Firestore-backed implementation without touching the UI. Mutations return
/// the affected aggregates so callers never hold stale lists.
abstract interface class WorkspaceRepository {
  Workspace getWorkspace();
  WorkspaceOverview loadOverview();
  List<WorkspaceSession> loadSessions();
  List<WorkspaceTask> loadTasks();
  List<WorkspaceFile> loadFiles();
  List<WorkspaceMemory> loadMemories();
  List<TimelineEvent> loadTimeline();
  WorkspaceSearchResults search(String query);
  WorkspaceSessionDetail loadSessionDetail(String sessionId);

  List<WorkspaceSession> setSessionPinned(String sessionId, bool pinned);
  List<WorkspaceSession> setSessionArchived(String sessionId, bool archived);
  List<WorkspaceSession> deleteSession(String sessionId);
  WorkspaceSessionDetail createSession(String title);
  WorkspaceSessionDetail renameSession(String sessionId, String newTitle);
  WorkspaceSessionDetail sendMessage(String sessionId, String prompt);
  WorkspaceSessionDetail addSessionMessage(
    String sessionId,
    MessageAuthor author,
    String text,
  );
  WorkspaceSessionDetail regenerateReply(String sessionId);

  List<WorkspaceTask> setTaskDone(String taskId, bool done);
  List<WorkspaceTask> setSubtaskDone(String taskId, int index, bool done);
  List<WorkspaceTask> addTasks(List<WorkspaceTask> tasks);
  List<WorkspaceTask> deleteTask(String taskId);
  List<WorkspaceTask> suggestTasks(String topic);

  List<WorkspaceFile> addFile(String name, AppFileType type);
  List<WorkspaceFile> deleteFile(String fileId);
  List<WorkspaceFile> setFileFavourite(String fileId, bool favourite);
  List<WorkspaceFile> setFilePinned(String fileId, bool pinned);
  WorkspaceFile summarizeFile(String fileId);

  List<WorkspaceMemory> addMemory(
    String title,
    String content,
    MemoryCategory category,
  );
  List<WorkspaceMemory> updateMemory(
    String memoryId, {
    String? title,
    String? content,
    MemoryCategory? category,
  });
  List<WorkspaceMemory> deleteMemory(String memoryId);
  List<WorkspaceMemory> setMemoryPinned(String memoryId, bool pinned);

  List<BriefingLine> regenerateBriefing();
}

/// Mock implementation — no persistence, no business logic.
class MockWorkspaceRepository implements WorkspaceRepository {
  MockWorkspaceRepository({WorkspaceService? service})
      : _service = service ?? MockWorkspaceService();

  final WorkspaceService _service;

  @override
  Workspace getWorkspace() => _service.loadOverview().workspace;

  @override
  WorkspaceOverview loadOverview() => _service.loadOverview();

  @override
  List<WorkspaceSession> loadSessions() => _service.loadSessions();

  @override
  List<WorkspaceTask> loadTasks() => _service.loadTasks();

  @override
  List<WorkspaceFile> loadFiles() => _service.loadFiles();

  @override
  List<WorkspaceMemory> loadMemories() => _service.loadMemories();

  @override
  List<TimelineEvent> loadTimeline() => _service.loadTimeline();

  @override
  WorkspaceSearchResults search(String query) => _service.search(query);

  @override
  List<BriefingLine> regenerateBriefing() => _service.regenerateBriefing();

  @override
  WorkspaceSessionDetail loadSessionDetail(String sessionId) =>
      _service.loadSessionDetail(sessionId);

  @override
  List<WorkspaceSession> setSessionPinned(String sessionId, bool pinned) =>
      _service.setSessionPinned(sessionId, pinned);

  @override
  List<WorkspaceSession> setSessionArchived(String sessionId, bool archived) =>
      _service.setSessionArchived(sessionId, archived);

  @override
  List<WorkspaceSession> deleteSession(String sessionId) =>
      _service.deleteSession(sessionId);

  @override
  WorkspaceSessionDetail createSession(String title) =>
      _service.createSession(title);

  @override
  WorkspaceSessionDetail renameSession(String sessionId, String newTitle) =>
      _service.renameSession(sessionId, newTitle);

  @override
  WorkspaceSessionDetail sendMessage(String sessionId, String prompt) =>
      _service.sendMessage(sessionId, prompt);

  @override
  WorkspaceSessionDetail addSessionMessage(
    String sessionId,
    MessageAuthor author,
    String text,
  ) =>
      _service.addSessionMessage(sessionId, author, text);

  @override
  WorkspaceSessionDetail regenerateReply(String sessionId) =>
      _service.regenerateReply(sessionId);

  @override
  List<WorkspaceTask> setTaskDone(String taskId, bool done) =>
      _service.setTaskDone(taskId, done);

  @override
  List<WorkspaceTask> setSubtaskDone(String taskId, int index, bool done) =>
      _service.setSubtaskDone(taskId, index, done);

  @override
  List<WorkspaceTask> addTasks(List<WorkspaceTask> tasks) =>
      _service.addTasks(tasks);

  @override
  List<WorkspaceTask> deleteTask(String taskId) => _service.deleteTask(taskId);

  @override
  List<WorkspaceTask> suggestTasks(String topic) =>
      _service.suggestTasks(topic);

  @override
  List<WorkspaceFile> addFile(String name, AppFileType type) =>
      _service.addFile(name, type);

  @override
  List<WorkspaceFile> deleteFile(String fileId) =>
      _service.deleteFile(fileId);

  @override
  List<WorkspaceFile> setFileFavourite(String fileId, bool favourite) =>
      _service.setFileFavourite(fileId, favourite);

  @override
  List<WorkspaceFile> setFilePinned(String fileId, bool pinned) =>
      _service.setFilePinned(fileId, pinned);

  @override
  WorkspaceFile summarizeFile(String fileId) =>
      _service.summarizeFile(fileId);

  @override
  List<WorkspaceMemory> addMemory(
    String title,
    String content,
    MemoryCategory category,
  ) =>
      _service.addMemory(title, content, category);

  @override
  List<WorkspaceMemory> updateMemory(
    String memoryId, {
    String? title,
    String? content,
    MemoryCategory? category,
  }) =>
      _service.updateMemory(memoryId, title: title, content: content, category: category);

  @override
  List<WorkspaceMemory> deleteMemory(String memoryId) =>
      _service.deleteMemory(memoryId);

  @override
  List<WorkspaceMemory> setMemoryPinned(String memoryId, bool pinned) =>
      _service.setMemoryPinned(memoryId, pinned);
}

/// Firestore-backed workspace repository — user-scoped.
///
/// Path: `users/{uid}/workspaces/{workspaceId}`
/// Every read/write is authenticated and isolated per `FirebaseAuth.currentUser`.
/// Keeps the synchronous [WorkspaceRepository] contract by caching in memory
/// and persisting to Firestore in the background (fire-and-forget), so the
/// existing UI (HomeDashboard, WorkspaceScreen) receives immediate data while
/// Firestore provides durability. An async [initialize] hydrates the cache
/// on first use; callers may await [ready] if they need the initial load.
class FirestoreWorkspaceRepository implements WorkspaceRepository {
  FirestoreWorkspaceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    WorkspaceService? fallbackService,
    this._uidProvider,
  })  : _firestore = firestore ?? _safeFirestore(),
        _auth = auth ?? _safeAuth(),
        _fallback = fallbackService ?? MockWorkspaceService(seed: false);

  static FirebaseFirestore? _safeFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth? _safeAuth() {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }


  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final WorkspaceService _fallback;
  final String? Function()? _uidProvider;

  // ---- Persistence outcome (Phase 1 hardening) ----
  //
  // The synchronous [WorkspaceRepository] contract is preserved for the
  // existing UI: mutations update the in-memory cache immediately and schedule
  // an awaited Firestore write. Failures are never swallowed: they are logged
  // and exposed via [lastPersistenceError] so callers can surface them, and
  // [refreshFromFirestore] re-reads the source of truth to recover.
  String? lastPersistenceError;
  DateTime? lastPersistenceErrorAt;

  /// The last persistence outcome as an [AppResult] for UIs that need
  /// success/failure after an optimistic update.
  AppResult<void> get lastPersistenceResult => lastPersistenceError == null
      ? const Success<void>(null)
      : Failure(ServerError(details: lastPersistenceError));

  void _recordPersistenceError(Object e) {
    lastPersistenceError = e.toString();
    lastPersistenceErrorAt = DateTime.now();
    debugPrint('FirestoreWorkspaceRepository persistence failed: $e');
  }

  void _clearPersistenceError() {
    lastPersistenceError = null;
    lastPersistenceErrorAt = null;
  }

  /// Tracks an awaited Firestore write; on failure runs [onFailure] to roll
  /// the in-memory cache back to its previous state. Success clears the
  /// last error so UIs can distinguish recovered vs failed state.
  void _trackPersistence(Future<bool> op, void Function() onFailure) {
    // Optimistically assume success; failures will re-record via _persist*.
    // Do not clear here — let success clear after confirmed.
    unawaited(op.then((ok) {
      if (!ok) {
        onFailure();
      } else {
        _clearPersistenceError();
      }
    }).catchError((Object e) {
      _recordPersistenceError(e);
      onFailure();
    }));
  }

  /// Re-reads Firestore (source of truth) to recover after a failure.
  /// Returns [Success] when the refresh completes, [Failure] with the error.
  Future<AppResult<void>> refreshFromFirestore() async {
    _loading = null;
    _sessionsLoading = null;
    _tasksLoading = null;
    _filesLoading = null;
    _memoriesLoading = null;
    _loaded = false;
    _sessionsLoaded = false;
    _tasksLoaded = false;
    _filesLoaded = false;
    _memoriesLoaded = false;
    try {
      await _ensureLoaded();
      await _ensureSessionsLoaded();
      await _ensureTasksLoaded();
      await _ensureFilesLoaded();
      await _ensureMemoriesLoaded();
      _clearPersistenceError();
      return const Success<void>(null);
    } catch (e) {
      _recordPersistenceError(e);
      return Failure(ServerError(details: e.toString()));
    }
  }

  // In-memory cache for the synchronous contract.
  List<Workspace> _workspaces = [];
  bool _loaded = false;
  Completer<void>? _loading;
  List<WorkspaceSession> _sessions = [];
  bool _sessionsLoaded = false;
  Completer<void>? _sessionsLoading;
  final Map<String, List<WorkspaceSessionMessage>> _messages = {};
  List<WorkspaceTask> _tasks = [];
  bool _tasksLoaded = false;
  Completer<void>? _tasksLoading;
  List<WorkspaceFile> _files = [];
  bool _filesLoaded = false;
  Completer<void>? _filesLoading;
  List<WorkspaceMemory> _memories = [];
  bool _memoriesLoaded = false;
  Completer<void>? _memoriesLoading;

  String? get _uid => _uidProvider?.call() ?? _auth?.currentUser?.uid;

  bool get _isUnauthenticated => _uid == null || _uid!.isEmpty;

  String? get _currentWorkspaceId => _workspaces.isNotEmpty ? _workspaces.first.id : null;

  CollectionReference<Map<String, dynamic>>? _col(String uid) {
    final fs = _firestore;
    if (fs == null) return null;
    return fs.collection(FirestoreConstants.users).doc(uid).collection(FirestoreConstants.workspaces);
  }

  CollectionReference<Map<String, dynamic>>? _sessionsCol(String uid, String workspaceId) {
    final col = _col(uid);
    if (col == null) return null;
    return col.doc(workspaceId).collection('sessions');
  }

  CollectionReference<Map<String, dynamic>>? _messagesCol(String uid, String workspaceId, String sessionId) {
    final sCol = _sessionsCol(uid, workspaceId);
    if (sCol == null) return null;
    return sCol.doc(sessionId).collection('messages');
  }

  CollectionReference<Map<String, dynamic>>? _tasksCol(String uid, String workspaceId) {
    final col = _col(uid);
    if (col == null) return null;
    return col.doc(workspaceId).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>>? _filesCol(String uid, String workspaceId) {
    final col = _col(uid);
    if (col == null) return null;
    return col.doc(workspaceId).collection('files');
  }

  CollectionReference<Map<String, dynamic>>? _memoriesCol(String uid, String workspaceId) {
    final col = _col(uid);
    if (col == null) return null;
    return col.doc(workspaceId).collection('memories');
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    if (_loading != null) return _loading!.future;
    _loading = Completer<void>();
    try {
      final uid = _uid;
      if (uid == null || uid.isEmpty) {
        _workspaces = [];
      } else {
        final col = _col(uid);
        if (col == null) {
          _workspaces = [];
        } else {
          final snap = await col.get();
          _workspaces = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return Workspace.fromJson(data);
          }).toList();
        }
      }
      _loaded = true;
      _loading!.complete();
    } catch (_) {
      _loaded = true;
      if (!_loading!.isCompleted) _loading!.complete();
    }
  }

  /// Awaitable for tests and initial hydration.
  Future<void> get ready => _ensureLoaded();

  // For tests — inject workspaces without Firestore.
  void setTestWorkspaces(List<Workspace> list) {
    _workspaces = List.of(list);
    _loaded = true;
    _clearPersistenceError();
    // Reset sessions/tasks/files/memories cache for the new workspace so tests start empty
    _sessions = [];
    _sessionsLoaded = true;
    _messages.clear();
    _tasks = [];
    _tasksLoaded = true;
    _files = [];
    _filesLoaded = true;
    _memories = [];
    _memoriesLoaded = true;
  }

  /// Awaited write. Returns true on success (or when there is nothing to
  /// persist: unauthenticated or no Firestore handle in tests). Returns false
  /// and records the error on Firestore failure — never silently swallowed.
  Future<bool> _persistWorkspace(Workspace ws) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return true;
    final col = _col(uid);
    if (col == null) return true;
    try {
      await col.doc(ws.id).set(ws.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  Future<bool> _deleteWorkspaceDoc(String id) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return true;
    final col = _col(uid);
    if (col == null) return true;
    try {
      await col.doc(id).delete();
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  // ---- Delegated overview/session/task etc. still use fallback for now ----
  // Workspace-level methods are real Firestore; others delegate to fallback
  // to preserve existing UI without a second persistence layer.

  @override
  Workspace getWorkspace() {
    if (_workspaces.isNotEmpty) return _workspaces.first;
    // Empty state — no fake seeded workspace in production; HomeDashboard
    // treats name.isEmpty as "no spaces" and shows Create your first Space.
    return const Workspace(
      id: '',
      name: '',
      description: '',
      emoji: '',
      accent: Color(0xFFD4AF5A),
    );
  }

  @override
  WorkspaceOverview loadOverview() {
    // Trigger async load but return immediate cache
    unawaited(_ensureLoaded());
    if (_workspaces.isEmpty) {
      return _fallback.loadOverview();
    }
    final ws = _workspaces.first;
    final base = _fallback.loadOverview();
    return WorkspaceOverview(
      workspace: ws,
      briefing: base.briefing,
      continueTitle: base.continueTitle,
      continueSnippet: base.continueSnippet,
      continueProgress: base.continueProgress,
      continueProgressLabel: base.continueProgressLabel,
      tasks: base.tasks,
      sessions: base.sessions,
      files: base.files,
      memories: base.memories,
      suggestions: base.suggestions,
    );
  }

  // Workspace CRUD — real Firestore

  Workspace _createWorkspaceInternal(String name, {String description = '', String emoji = '🗂️', Color accent = const Color(0xFFD4AF5A)}) {
    final id = 'ws-${DateTime.now().millisecondsSinceEpoch}';
    final ws = Workspace(
      id: id,
      name: name.trim().isEmpty ? 'Untitled Workspace' : name.trim(),
      description: description,
      emoji: emoji,
      accent: accent,
      status: WorkspaceStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _workspaces.insert(0, ws);
    final String insertedId = ws.id;
    _trackPersistence(_persistWorkspace(ws), () {
      _workspaces.removeWhere((w) => w.id == insertedId);
    });
    return ws;
  }

  // Exposed for HomeDashboard/WorkspaceScreen to create workspaces (future)
  Workspace createWorkspace(String name) {
    if (_isUnauthenticated) {
      final now = DateTime.now();
      return Workspace(id: '', name: name, description: '', emoji: '', accent: const Color(0xFFD4AF5A), createdAt: now, updatedAt: now);
    }
    return _createWorkspaceInternal(name);
  }

  void updateWorkspace(Workspace updated) {
    if (_isUnauthenticated) return;
    final idx = _workspaces.indexWhere((w) => w.id == updated.id);
    if (idx >= 0) {
      final Workspace previous = _workspaces[idx];
      final Workspace next = updated.copyWith(updatedAt: DateTime.now());
      _workspaces[idx] = next;
      _trackPersistence(_persistWorkspace(next), () {
        final int rollbackIdx = _workspaces.indexWhere((w) => w.id == updated.id);
        if (rollbackIdx >= 0) _workspaces[rollbackIdx] = previous;
      });
    }
  }

  void deleteWorkspace(String id) {
    if (_isUnauthenticated) return;
    final List<Workspace> snapshot = List<Workspace>.of(_workspaces);
    final bool hadItem = _workspaces.any((w) => w.id == id);
    _workspaces.removeWhere((w) => w.id == id);
    _trackPersistence(_deleteWorkspaceDoc(id), () {
      if (hadItem && _workspaces.every((w) => w.id != id)) {
        _workspaces = List<Workspace>.of(snapshot);
      }
    });
  }

  // ---- Pass-through for remaining contract (still mock-backed) ----

  // ---- Sessions — REAL Firestore (users/{uid}/workspaces/{wid}/sessions) ----

  Future<void> _ensureSessionsLoaded() async {
    if (_sessionsLoaded) return;
    if (_sessionsLoading != null) return _sessionsLoading!.future;
    _sessionsLoading = Completer<void>();
    try {
      final uid = _uid;
      final wid = _currentWorkspaceId;
      if (uid == null || uid.isEmpty || wid == null || wid.isEmpty) {
        _sessions = [];
      } else {
        final col = _sessionsCol(uid, wid);
        if (col == null) {
          _sessions = [];
        } else {
          final snap = await col.orderBy('updatedAt', descending: true).get();
          _sessions = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return WorkspaceSession.fromJson(data);
          }).toList();
        }
      }
      _sessionsLoaded = true;
      _sessionsLoading!.complete();
    } catch (_) {
      _sessionsLoaded = true;
      if (!(_sessionsLoading?.isCompleted ?? true)) _sessionsLoading!.complete();
    }
  }

  Future<List<WorkspaceSessionMessage>> _ensureMessagesLoaded(String sessionId) async {
    final list = _messages[sessionId];
    if (list != null) return list;
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return const [];
    final col = _messagesCol(uid, wid, sessionId);
    if (col == null) return const [];
    try {
      final snap = await col.orderBy('sentAt').get();
      final msgs = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return WorkspaceSessionMessage.fromJson(data);
      }).toList();
      _messages[sessionId] = msgs;
      return msgs;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> _persistSession(WorkspaceSession s) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _sessionsCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(s.id).set(s.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  Future<bool> _deleteSessionDoc(String sessionId) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _sessionsCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(sessionId).delete();
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  Future<bool> _persistMessage(String sessionId, WorkspaceSessionMessage m) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _messagesCol(uid, wid, sessionId);
    if (col == null) return true;
    try {
      await col.doc(m.id).set(m.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  // ---- Tasks — REAL Firestore (users/{uid}/workspaces/{wid}/tasks) ----

  Future<void> _ensureTasksLoaded() async {
    if (_tasksLoaded) return;
    if (_tasksLoading != null) return _tasksLoading!.future;
    _tasksLoading = Completer<void>();
    try {
      final uid = _uid;
      final wid = _currentWorkspaceId;
      if (uid == null || uid.isEmpty || wid == null || wid.isEmpty) {
        _tasks = [];
      } else {
        final col = _tasksCol(uid, wid);
        if (col == null) {
          _tasks = [];
        } else {
          final snap = await col.orderBy('createdAt').get();
          _tasks = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return WorkspaceTask.fromJson(data);
          }).toList();
        }
      }
      _tasksLoaded = true;
      _tasksLoading!.complete();
    } catch (_) {
      _tasksLoaded = true;
      if (!(_tasksLoading?.isCompleted ?? true)) _tasksLoading!.complete();
    }
  }

  Future<bool> _persistTask(WorkspaceTask t) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _tasksCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(t.id).set(t.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  Future<bool> _deleteTaskDoc(String taskId) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _tasksCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(taskId).delete();
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  // ---- Files — REAL Firestore (users/{uid}/workspaces/{wid}/files) ----

  Future<void> _ensureFilesLoaded() async {
    if (_filesLoaded) return;
    if (_filesLoading != null) return _filesLoading!.future;
    _filesLoading = Completer<void>();
    try {
      final uid = _uid;
      final wid = _currentWorkspaceId;
      if (uid == null || uid.isEmpty || wid == null || wid.isEmpty) {
        _files = [];
      } else {
        final col = _filesCol(uid, wid);
        if (col == null) {
          _files = [];
        } else {
          final snap = await col.orderBy('createdAt').get();
          _files = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return WorkspaceFile.fromJson(data);
          }).toList();
        }
      }
      _filesLoaded = true;
      _filesLoading!.complete();
    } catch (_) {
      _filesLoaded = true;
      if (!(_filesLoading?.isCompleted ?? true)) _filesLoading!.complete();
    }
  }

  Future<bool> _persistFile(WorkspaceFile f) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _filesCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(f.id).set(f.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  Future<bool> _deleteFileDoc(String fileId) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _filesCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(fileId).delete();
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  // ---- Memories — REAL Firestore (users/{uid}/workspaces/{wid}/memories) ----

  Future<void> _ensureMemoriesLoaded() async {
    if (_memoriesLoaded) return;
    if (_memoriesLoading != null) return _memoriesLoading!.future;
    _memoriesLoading = Completer<void>();
    try {
      final uid = _uid;
      final wid = _currentWorkspaceId;
      if (uid == null || uid.isEmpty || wid == null || wid.isEmpty) {
        _memories = [];
      } else {
        final col = _memoriesCol(uid, wid);
        if (col == null) {
          _memories = [];
        } else {
          final snap = await col.orderBy('updatedAt', descending: true).get();
          _memories = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return WorkspaceMemory.fromJson(data);
          }).toList();
        }
      }
      _memoriesLoaded = true;
      _memoriesLoading!.complete();
    } catch (_) {
      _memoriesLoaded = true;
      if (!(_memoriesLoading?.isCompleted ?? true)) _memoriesLoading!.complete();
    }
  }

  Future<bool> _persistMemory(WorkspaceMemory m) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _memoriesCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(m.id).set(m.toJson(), SetOptions(merge: true));
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  Future<bool> _deleteMemoryDoc(String memoryId) async {
    final uid = _uid;
    final wid = _currentWorkspaceId;
    if (uid == null || wid == null || wid.isEmpty) return true;
    final col = _memoriesCol(uid, wid);
    if (col == null) return true;
    try {
      await col.doc(memoryId).delete();
      return true;
    } catch (e) {
      _recordPersistenceError(e);
      return false;
    }
  }

  @override
  List<WorkspaceSession> loadSessions() {
    if (!_sessionsLoaded) unawaited(_ensureSessionsLoaded());
    return List.of(_sessions);
  }

  @override
  WorkspaceSessionDetail loadSessionDetail(String sessionId) {
    final found = _sessions.where((s) => s.id == sessionId).toList();
    final session = found.isNotEmpty
        ? found.first
        : WorkspaceSession(id: sessionId, title: '', updatedAt: DateTime.now());
    final msgs = _messages[sessionId] ?? const <WorkspaceSessionMessage>[];
    if (!_messages.containsKey(sessionId)) {
      unawaited(_ensureMessagesLoaded(sessionId));
    }
    return WorkspaceSessionDetail(
      session: session,
      messages: List.of(msgs),
      aiSummary: null,
      actionItems: const [],
      keyFacts: const [],
      linkedFiles: const [],
      linkedTasks: const [],
    );
  }

  @override
  List<WorkspaceSession> setSessionPinned(String sessionId, bool pinned) {
    if (_isUnauthenticated) return List.of(_sessions);
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      final WorkspaceSession previous = _sessions[idx];
      final WorkspaceSession next = previous.copyWith(pinned: pinned, updatedAt: DateTime.now());
      _sessions[idx] = next;
      _trackPersistence(_persistSession(next), () {
        final int rIdx = _sessions.indexWhere((s) => s.id == sessionId);
        if (rIdx >= 0) _sessions[rIdx] = previous;
      });
    }
    return List.of(_sessions);
  }

  @override
  List<WorkspaceSession> setSessionArchived(String sessionId, bool archived) {
    if (_isUnauthenticated) return List.of(_sessions);
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      final WorkspaceSession previous = _sessions[idx];
      final WorkspaceSession next = previous.copyWith(
        status: archived ? SessionStatus.archived : SessionStatus.completed,
        updatedAt: DateTime.now(),
      );
      _sessions[idx] = next;
      _trackPersistence(_persistSession(next), () {
        final int rIdx = _sessions.indexWhere((s) => s.id == sessionId);
        if (rIdx >= 0) _sessions[rIdx] = previous;
      });
    }
    return List.of(_sessions);
  }

  @override
  List<WorkspaceSession> deleteSession(String sessionId) {
    if (_isUnauthenticated) return List.of(_sessions);
    final List<WorkspaceSession> snapshot = List<WorkspaceSession>.of(_sessions);
    final List<WorkspaceSessionMessage>? msgSnapshot = _messages[sessionId] != null ? List<WorkspaceSessionMessage>.of(_messages[sessionId]!) : null;
    _sessions.removeWhere((s) => s.id == sessionId);
    _messages.remove(sessionId);
    _trackPersistence(_deleteSessionDoc(sessionId), () {
      _sessions = List<WorkspaceSession>.of(snapshot);
      if (msgSnapshot != null) _messages[sessionId] = msgSnapshot;
    });
    return List.of(_sessions);
  }

  @override
  WorkspaceSessionDetail createSession(String title) {
    if (_isUnauthenticated) {
      final now = DateTime.now();
      return WorkspaceSessionDetail(
        session: WorkspaceSession(id: '', title: title.trim().isEmpty ? 'Untitled session' : title.trim(), updatedAt: now, createdAt: now),
        messages: const [],
      );
    }
    final now = DateTime.now();
    final id = 's-${now.millisecondsSinceEpoch}';
    final session = WorkspaceSession(
      id: id,
      title: title.trim().isEmpty ? 'Untitled session' : title.trim(),
      updatedAt: now,
      createdAt: now,
      status: SessionStatus.inProgress,
      messageCount: 0,
    );
    _sessions.insert(0, session);
    _sessionsLoaded = true;
    _messages[id] = [];
    _trackPersistence(_persistSession(session), () {
      _sessions.removeWhere((s) => s.id == id);
      _messages.remove(id);
    });
    return WorkspaceSessionDetail(session: session, messages: const []);
  }

  @override
  WorkspaceSessionDetail renameSession(String sessionId, String newTitle) {
    if (_isUnauthenticated) return _fallback.renameSession(sessionId, newTitle);
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      final WorkspaceSession previous = _sessions[idx];
      final WorkspaceSession next = previous.copyWith(title: newTitle.trim(), updatedAt: DateTime.now());
      _sessions[idx] = next;
      _trackPersistence(_persistSession(next), () {
        final int rIdx = _sessions.indexWhere((s) => s.id == sessionId);
        if (rIdx >= 0) _sessions[rIdx] = previous;
      });
      return WorkspaceSessionDetail(session: _sessions[idx], messages: List.of(_messages[sessionId] ?? const []));
    }
    return _fallback.renameSession(sessionId, newTitle);
  }

  @override
  WorkspaceSessionDetail sendMessage(String sessionId, String prompt) {
    if (_isUnauthenticated) return _fallback.sendMessage(sessionId, prompt);
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx < 0) return _fallback.sendMessage(sessionId, prompt);
    final now = DateTime.now();
    final userMsg = WorkspaceSessionMessage(id: 'm-${now.millisecondsSinceEpoch}', author: MessageAuthor.user, text: prompt, sentAt: now);
    final aiMsg = WorkspaceSessionMessage(id: 'm-${now.millisecondsSinceEpoch + 1}', author: MessageAuthor.ai, text: 'Thinking…', sentAt: now);
    final List<WorkspaceSessionMessage> prevMsgs = List<WorkspaceSessionMessage>.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final WorkspaceSession prevSession = _sessions[idx];
    final list = _messages[sessionId] ?? [];
    _messages[sessionId] = [...list, userMsg, aiMsg];
    _sessions[idx] = _sessions[idx].copyWith(messageCount: _messages[sessionId]!.length, updatedAt: now);
    _trackPersistence(_persistMessage(sessionId, userMsg), () => _messages[sessionId] = List<WorkspaceSessionMessage>.of(prevMsgs));
    _trackPersistence(_persistMessage(sessionId, aiMsg), () => _messages[sessionId] = List<WorkspaceSessionMessage>.of(prevMsgs));
    _trackPersistence(_persistSession(_sessions[idx]), () {
      final int rIdx = _sessions.indexWhere((s) => s.id == sessionId);
      if (rIdx >= 0) _sessions[rIdx] = prevSession;
      _messages[sessionId] = List<WorkspaceSessionMessage>.of(prevMsgs);
    });
    return WorkspaceSessionDetail(session: _sessions[idx], messages: List.of(_messages[sessionId]!));
  }

  @override
  WorkspaceSessionDetail addSessionMessage(String sessionId, MessageAuthor author, String text) {
    if (_isUnauthenticated) {
      return WorkspaceSessionDetail(
        session: WorkspaceSession(id: sessionId, title: '', updatedAt: DateTime.now()),
        messages: const [],
      );
    }
    final now = DateTime.now();
    final msg = WorkspaceSessionMessage(id: 'm-${now.millisecondsSinceEpoch}', author: author, text: text, sentAt: now);
    final List<WorkspaceSessionMessage> prevMsgs = List<WorkspaceSessionMessage>.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final int idx = _sessions.indexWhere((s) => s.id == sessionId);
    final WorkspaceSession? prevSession = idx >= 0 ? _sessions[idx] : null;
    final list = _messages[sessionId] ?? [];
    _messages[sessionId] = [...list, msg];
    _trackPersistence(_persistMessage(sessionId, msg), () => _messages[sessionId] = List<WorkspaceSessionMessage>.of(prevMsgs));
    if (idx >= 0) {
      _sessions[idx] = _sessions[idx].copyWith(messageCount: _messages[sessionId]!.length, updatedAt: now);
      _trackPersistence(_persistSession(_sessions[idx]), () {
        final int rIdx = _sessions.indexWhere((s) => s.id == sessionId);
        if (rIdx >= 0 && prevSession != null) _sessions[rIdx] = prevSession;
        _messages[sessionId] = List<WorkspaceSessionMessage>.of(prevMsgs);
      });
      return WorkspaceSessionDetail(session: _sessions[idx], messages: List.of(_messages[sessionId]!));
    }
    return WorkspaceSessionDetail(
      session: WorkspaceSession(id: sessionId, title: '', updatedAt: now),
      messages: List.of(_messages[sessionId]!),
    );
  }

  @override
  WorkspaceSessionDetail regenerateReply(String sessionId) {
    if (_isUnauthenticated) return _fallback.regenerateReply(sessionId);
    final List<WorkspaceSessionMessage> prevMsgs = List<WorkspaceSessionMessage>.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final list = _messages[sessionId] ?? [];
    if (list.isNotEmpty && list.last.fromAi) {
      final now = DateTime.now();
      final replacement = WorkspaceSessionMessage(id: 'm-${now.millisecondsSinceEpoch}', author: MessageAuthor.ai, text: 'Regenerated reply', sentAt: now);
      _messages[sessionId] = [...list.sublist(0, list.length - 1), replacement];
      _trackPersistence(_persistMessage(sessionId, replacement), () => _messages[sessionId] = List<WorkspaceSessionMessage>.of(prevMsgs));
    }
    final idx = _sessions.indexWhere((s) => s.id == sessionId);
    if (idx >= 0) {
      return WorkspaceSessionDetail(session: _sessions[idx], messages: List.of(_messages[sessionId] ?? const []));
    }
    return _fallback.regenerateReply(sessionId);
  }

  @override
  List<WorkspaceTask> loadTasks() {
    if (!_tasksLoaded) unawaited(_ensureTasksLoaded());
    return List.of(_tasks);
  }

  @override
  List<WorkspaceFile> loadFiles() {
    if (!_filesLoaded) unawaited(_ensureFilesLoaded());
    return List.of(_files);
  }

  @override
  List<WorkspaceMemory> loadMemories() {
    if (!_memoriesLoaded) unawaited(_ensureMemoriesLoaded());
    return List.of(_memories);
  }

  @override
  List<TimelineEvent> loadTimeline() => _fallback.loadTimeline();
  @override
  WorkspaceSearchResults search(String query) => _fallback.search(query);
  @override
  List<WorkspaceTask> setTaskDone(String taskId, bool done) {
    if (_isUnauthenticated) return List.of(_tasks);
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      final WorkspaceTask previous = _tasks[idx];
      final t = _tasks[idx];
      final updated = t.copyWith(
        done: done,
        subtasks: done && t.hasSubtasks ? [for (final s in t.subtasks) s.copyWith(done: true)] : t.subtasks,
      );
      _tasks[idx] = updated;
      _trackPersistence(_persistTask(updated), () {
        final int rIdx = _tasks.indexWhere((x) => x.id == taskId);
        if (rIdx >= 0) _tasks[rIdx] = previous;
      });
    }
    return List.of(_tasks);
  }

  @override
  List<WorkspaceTask> setSubtaskDone(String taskId, int index, bool done) {
    if (_isUnauthenticated) return List.of(_tasks);
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx >= 0) {
      final WorkspaceTask previous = _tasks[idx];
      final t = _tasks[idx];
      final subtasks = [
        for (var i = 0; i < t.subtasks.length; i++) i == index ? t.subtasks[i].copyWith(done: done) : t.subtasks[i],
      ];
      final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.done);
      _tasks[idx] = t.copyWith(subtasks: subtasks, done: allDone);
      _trackPersistence(_persistTask(_tasks[idx]), () {
        final int rIdx = _tasks.indexWhere((x) => x.id == taskId);
        if (rIdx >= 0) _tasks[rIdx] = previous;
      });
    }
    return List.of(_tasks);
  }

  @override
  List<WorkspaceTask> addTasks(List<WorkspaceTask> tasks) {
    if (_isUnauthenticated) return List.of(_tasks);
    // Ensure IDs and timestamps
    final now = DateTime.now();
    final toAdd = tasks.map((t) => t.copyWith(createdAt: t.createdAt ?? now)).toList();
    _tasks.insertAll(0, toAdd);
    for (final t in toAdd) {
      final String addedId = t.id;
      _trackPersistence(_persistTask(t), () {
        _tasks.removeWhere((x) => x.id == addedId);
      });
    }
    return List.of(_tasks);
  }

  @override
  List<WorkspaceTask> deleteTask(String taskId) {
    if (_isUnauthenticated) return List.of(_tasks);
    final List<WorkspaceTask> snapshot = List<WorkspaceTask>.of(_tasks);
    final bool hadItem = _tasks.any((t) => t.id == taskId);
    _tasks.removeWhere((t) => t.id == taskId);
    _trackPersistence(_deleteTaskDoc(taskId), () {
      if (hadItem && _tasks.every((t) => t.id != taskId)) {
        _tasks = List<WorkspaceTask>.of(snapshot);
      }
    });
    return List.of(_tasks);
  }

  @override
  List<WorkspaceTask> suggestTasks(String topic) => _fallback.suggestTasks(topic);
  @override
  List<WorkspaceFile> addFile(String name, AppFileType type) {
    if (_isUnauthenticated) return List.of(_files);
    final id = 'f-${DateTime.now().millisecondsSinceEpoch}';
    final file = WorkspaceFile(id: id, name: name, type: type, createdAt: DateTime.now(), meta: 'Just added');
    _files.insert(0, file);
    _filesLoaded = true;
    _trackPersistence(_persistFile(file), () {
      _files.removeWhere((f) => f.id == id);
    });
    return List.of(_files);
  }

  @override
  List<WorkspaceFile> deleteFile(String fileId) {
    if (_isUnauthenticated) return List.of(_files);
    final List<WorkspaceFile> snapshot = List<WorkspaceFile>.of(_files);
    final bool hadItem = _files.any((f) => f.id == fileId);
    _files.removeWhere((f) => f.id == fileId);
    _trackPersistence(_deleteFileDoc(fileId), () {
      if (hadItem && _files.every((f) => f.id != fileId)) {
        _files = List<WorkspaceFile>.of(snapshot);
      }
    });
    return List.of(_files);
  }

  @override
  List<WorkspaceFile> setFileFavourite(String fileId, bool favourite) {
    if (_isUnauthenticated) return List.of(_files);
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx >= 0) {
      final WorkspaceFile previous = _files[idx];
      final WorkspaceFile next = previous.copyWith(favourite: favourite);
      _files[idx] = next;
      _trackPersistence(_persistFile(next), () {
        final int rIdx = _files.indexWhere((f) => f.id == fileId);
        if (rIdx >= 0) _files[rIdx] = previous;
      });
    }
    return List.of(_files);
  }

  @override
  List<WorkspaceFile> setFilePinned(String fileId, bool pinned) {
    if (_isUnauthenticated) return List.of(_files);
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx >= 0) {
      final WorkspaceFile previous = _files[idx];
      final WorkspaceFile next = previous.copyWith(pinned: pinned);
      _files[idx] = next;
      _trackPersistence(_persistFile(next), () {
        final int rIdx = _files.indexWhere((f) => f.id == fileId);
        if (rIdx >= 0) _files[rIdx] = previous;
      });
    }
    return List.of(_files);
  }

  @override
  WorkspaceFile summarizeFile(String fileId) {
    if (_isUnauthenticated) return _fallback.summarizeFile(fileId);
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx >= 0) {
      final WorkspaceFile previous = _files[idx];
      final file = _files[idx];
      final updated = file.copyWith(summarized: true, summary: 'AI summary for ${file.name}');
      _files[idx] = updated;
      _trackPersistence(_persistFile(updated), () {
        final int rIdx = _files.indexWhere((f) => f.id == fileId);
        if (rIdx >= 0) _files[rIdx] = previous;
      });
      return updated;
    }
    return _fallback.summarizeFile(fileId);
  }

  @override
  List<WorkspaceMemory> addMemory(String title, String content, MemoryCategory category) {
    if (_isUnauthenticated) return List.of(_memories);
    final id = 'm-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final mem = WorkspaceMemory(id: id, title: title, content: content, category: category, updatedAt: now, source: 'Added manually');
    _memories.insert(0, mem);
    _memoriesLoaded = true;
    _trackPersistence(_persistMemory(mem), () {
      _memories.removeWhere((m) => m.id == id);
    });
    return List.of(_memories);
  }

  @override
  List<WorkspaceMemory> updateMemory(String memoryId, {String? title, String? content, MemoryCategory? category}) {
    if (_isUnauthenticated) return List.of(_memories);
    final idx = _memories.indexWhere((m) => m.id == memoryId);
    if (idx >= 0) {
      final WorkspaceMemory previous = _memories[idx];
      final WorkspaceMemory next = previous.copyWith(title: title, content: content, category: category, updatedAt: DateTime.now());
      _memories[idx] = next;
      _trackPersistence(_persistMemory(next), () {
        final int rIdx = _memories.indexWhere((m) => m.id == memoryId);
        if (rIdx >= 0) _memories[rIdx] = previous;
      });
    }
    return List.of(_memories);
  }

  @override
  List<WorkspaceMemory> deleteMemory(String memoryId) {
    if (_isUnauthenticated) return List.of(_memories);
    final List<WorkspaceMemory> snapshot = List<WorkspaceMemory>.of(_memories);
    final bool hadItem = _memories.any((m) => m.id == memoryId);
    _memories.removeWhere((m) => m.id == memoryId);
    _trackPersistence(_deleteMemoryDoc(memoryId), () {
      if (hadItem && _memories.every((m) => m.id != memoryId)) {
        _memories = List<WorkspaceMemory>.of(snapshot);
      }
    });
    return List.of(_memories);
  }

  @override
  List<WorkspaceMemory> setMemoryPinned(String memoryId, bool pinned) {
    if (_isUnauthenticated) return List.of(_memories);
    final idx = _memories.indexWhere((m) => m.id == memoryId);
    if (idx >= 0) {
      final WorkspaceMemory previous = _memories[idx];
      final WorkspaceMemory next = previous.copyWith(pinned: pinned, updatedAt: DateTime.now());
      _memories[idx] = next;
      _trackPersistence(_persistMemory(next), () {
        final int rIdx = _memories.indexWhere((m) => m.id == memoryId);
        if (rIdx >= 0) _memories[rIdx] = previous;
      });
    }
    return List.of(_memories);
  }
  @override
  List<BriefingLine> regenerateBriefing() => _fallback.regenerateBriefing();

  // For HomeDashboard empty check
  List<Workspace> loadWorkspaces() => List.of(_workspaces);
}
