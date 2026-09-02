import '../../../../core/design_system/design_system.dart';
import '../data/mock/mock_workspace_data.dart';
import '../domain/models/workspace.dart';
import '../domain/models/workspace_file.dart';
import '../domain/models/workspace_memory.dart';
import '../domain/models/workspace_overview.dart';
import '../domain/models/workspace_search.dart';
import '../domain/models/workspace_session.dart';
import '../domain/models/workspace_session_detail.dart';
import '../domain/models/workspace_session_message.dart';
import '../domain/models/workspace_suggestion.dart';
import '../domain/models/workspace_task.dart';
import '../domain/models/workspace_timeline.dart';
import 'workspace_ai_service.dart';

/// Provides workspace content and mutations.
///
/// Sprint 1 is mock-backed; Sprint 2 swaps in a real implementation without
/// touching the UI. All AI-generated content is produced by the injected
/// [WorkspaceAIService] — never by the UI.
abstract interface class WorkspaceService {
  WorkspaceOverview loadOverview();
  List<WorkspaceSession> loadSessions();
  List<WorkspaceTask> loadTasks();
  List<WorkspaceFile> loadFiles();
  List<WorkspaceMemory> loadMemories();
  List<TimelineEvent> loadTimeline();
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
  WorkspaceSearchResults search(String query);
}

/// Mock implementation â€” holds a mutable in-memory snapshot seeded from
/// [MockWorkspaceData]. No persistence, no business logic.
///
/// [seed] selects which starting data to use: `true` loads the full
/// [MockWorkspaceData] fixture (tests, previews), `false` starts a completely
/// empty workspace (neutral metadata + empty briefing, no fake content).
class MockWorkspaceService implements WorkspaceService {
  MockWorkspaceService({WorkspaceAIService? ai, this.seed = true})
      : _ai = ai ?? const MockWorkspaceAIService() {
    _sessions =
        seed ? List.of(MockWorkspaceData.sessions) : <WorkspaceSession>[];
    _tasks = seed ? List.of(MockWorkspaceData.tasks) : <WorkspaceTask>[];
    _files = seed ? List.of(MockWorkspaceData.files) : <WorkspaceFile>[];
    _memories =
        seed ? List.of(MockWorkspaceData.memories) : <WorkspaceMemory>[];
    _messages = <String, List<WorkspaceSessionMessage>>{};
    _briefing = seed ? List.of(MockWorkspaceData.briefing) : _emptyBriefing;
    _briefingIndex = 0;
    _sequence = seed
        ? MockWorkspaceData.tasks.length + MockWorkspaceData.sessions.length
        : 0;

    if (seed) {
      for (final entry in MockWorkspaceData.sessionPrompts.entries) {
        final session = _sessions.firstWhere((s) => s.id == entry.key);
        final turns = <WorkspaceSessionMessage>[];
        for (var i = 0; i < entry.value.length; i++) {
          final prompt = entry.value[i];
          turns.add(
            WorkspaceSessionMessage(
              id: '${entry.key}-u$i',
              author: MessageAuthor.user,
              text: prompt,
            ),
          );
          turns.add(
            WorkspaceSessionMessage(
              id: '${entry.key}-a$i',
              author: MessageAuthor.ai,
              text: _ai.replyTo(session.title, prompt, i + 1),
            ),
          );
        }
        _messages[entry.key] = turns;
      }

      // Keep the seeded messageCount in sync with the generated turns.
      for (final entry in _messages.entries) {
        _sessions = [
          for (final s in _sessions)
            if (s.id == entry.key) s.copyWith(messageCount: entry.value.length) else s,
        ];
      }
    }

    _timeline = seed ? _seedTimeline() : <TimelineEvent>[];
  }

  final bool seed;

  final WorkspaceAIService _ai;
  late List<WorkspaceSession> _sessions;
  late List<WorkspaceTask> _tasks;
  late List<WorkspaceFile> _files;
  late List<WorkspaceMemory> _memories;
  late List<TimelineEvent> _timeline;
  late List<BriefingLine> _briefing;
  late int _briefingIndex;
  late Map<String, List<WorkspaceSessionMessage>> _messages;
  late int _sequence;

  int _nextId() => ++_sequence;

  // ---- Timeline helpers ----

  TimelineEvent _event(
    TimelineEventType type,
    String title, {
    String? description,
    DateTime? at,
    String? refId,
  }) {
    final event = TimelineEvent(
      id: 'tl-${_nextId()}',
      type: type,
      title: title,
      description: description,
      occurredAt: at ?? DateTime.now(),
      refId: refId,
    );
    _timeline.insert(0, event);
    return event;
  }

  /// Builds the initial history from the seeded data (oldest last).
  List<TimelineEvent> _seedTimeline() {
    final seeded = <TimelineEvent>[];
    for (final f in _files) {
      seeded.add(TimelineEvent(
        id: 'tl-seed-file-${f.id}',
        type: TimelineEventType.file,
        title: 'File added',
        description: f.name,
        occurredAt: f.createdAt ?? DateTime.now(),
        refId: f.id,
      ));
    }
    for (final m in _memories) {
      seeded.add(TimelineEvent(
        id: 'tl-seed-mem-${m.id}',
        type: TimelineEventType.memory,
        title: 'Memory saved',
        description: m.title,
        occurredAt: m.updatedAt ?? DateTime.now(),
        refId: m.id,
      ));
    }
    for (final t in _tasks) {
      seeded.add(TimelineEvent(
        id: 'tl-seed-task-${t.id}',
        type: TimelineEventType.task,
        title: t.done ? 'Task completed' : 'Task added',
        description: t.title,
        occurredAt: t.createdAt ?? DateTime.now(),
        refId: t.id,
      ));
    }
    for (final s in _sessions) {
      seeded.add(TimelineEvent(
        id: 'tl-seed-sess-${s.id}',
        type: TimelineEventType.session,
        title: 'Chat started',
        description: s.title,
        occurredAt: s.createdAt ?? s.updatedAt,
        refId: s.id,
      ));
    }
    seeded.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return seeded;
  }

  // ---- Loaders ----

  @override
  WorkspaceOverview loadOverview() {
    final activeTasks = _tasks.where((t) => !t.archived).toList();
    final activeSessions = _sessions.where((s) => !s.archived).toList();
    return WorkspaceOverview(
      workspace: seed ? MockWorkspaceData.workspace : _newWorkspace(),
      briefing: _briefing,
      continueTitle: seed ? MockWorkspaceData.continueTitle : null,
      continueSnippet: seed ? MockWorkspaceData.continueSnippet : null,
      continueProgress: seed ? MockWorkspaceData.continueProgress : null,
      continueProgressLabel: seed ? MockWorkspaceData.continueProgressLabel : null,
      tasks: activeTasks,
      sessions: activeSessions,
      files: _files,
      memories: _memories,
      suggestions:
          seed ? MockWorkspaceData.suggestions : const <WorkspaceSuggestion>[],
    );
  }

  @override
  List<WorkspaceSession> loadSessions() => List.of(_sessions);

  @override
  List<WorkspaceTask> loadTasks() => List.of(_tasks);

  @override
  List<WorkspaceFile> loadFiles() => List.of(_files);

  @override
  List<WorkspaceMemory> loadMemories() => List.of(_memories);

  @override
  List<TimelineEvent> loadTimeline() => List.of(_timeline);

  @override
  WorkspaceSearchResults search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const WorkspaceSearchResults();
    return WorkspaceSearchResults(
      sessions: _sessions
          .where(
            (s) =>
                s.title.toLowerCase().contains(q) ||
                (s.purpose ?? '').toLowerCase().contains(q) ||
                (s.preview ?? '').toLowerCase().contains(q),
          )
          .toList(),
      tasks: _tasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                (t.contextLabel ?? '').toLowerCase().contains(q),
          )
          .toList(),
      files: _files
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.type.label.toLowerCase().contains(q),
          )
          .toList(),
      memories: _memories
          .where(
            (m) =>
                m.title.toLowerCase().contains(q) ||
                m.content.toLowerCase().contains(q),
          )
          .toList(),
      timeline: _timeline
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                (e.description ?? '').toLowerCase().contains(q),
          )
          .toList(),
    );
  }

  @override
  List<BriefingLine> regenerateBriefing() {
    if (!seed) return loadOverview().briefing;
    final pool = MockWorkspaceData.briefingVariants;
    _briefingIndex = (_briefingIndex + 1) % pool.length;
    _briefing = List.of(pool[_briefingIndex]);
    return loadOverview().briefing;
  }

  @override
  WorkspaceSessionDetail loadSessionDetail(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final messages = List.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final linkedFiles = [
      for (final id in session.linkedFileIds)
        MockWorkspaceData.files.firstWhere(
          (f) => f.id == id,
          orElse: () => WorkspaceFile(
            id: id,
            name: 'file',
            type: AppFileType.unknown,
          ),
        ),
    ];
    final linkedTasks = [
      for (final id in session.linkedTaskIds)
        _tasks.firstWhere(
          (t) => t.id == id,
          orElse: () => WorkspaceTask(id: id, title: 'Task', done: false),
        ),
    ];
    return WorkspaceSessionDetail(
      session: session,
      messages: messages,
      aiSummary: seed ? _ai.sessionSummary(session.title) : null,
      actionItems: seed ? _ai.actionItemsFor(session.title) : const [],
      keyFacts: seed ? _ai.keyFactsFor(session.title) : const [],
      linkedFiles: linkedFiles,
      linkedTasks: linkedTasks,
    );
  }

  // ---- Session mutations ----

  @override
  List<WorkspaceSession> setSessionPinned(String sessionId, bool pinned) {
    _sessions = [
      for (final s in _sessions)
        if (s.id == sessionId) s.copyWith(pinned: pinned) else s,
    ];
    return loadSessions();
  }

  @override
  List<WorkspaceSession> setSessionArchived(String sessionId, bool archived) {
    _sessions = [
      for (final s in _sessions)
        if (s.id == sessionId)
          s.copyWith(status: archived ? SessionStatus.archived : SessionStatus.completed)
        else
          s,
    ];
    return loadSessions();
  }

  @override
  List<WorkspaceSession> deleteSession(String sessionId) {
    _sessions = _sessions.where((s) => s.id != sessionId).toList();
    _messages.remove(sessionId);
    return loadSessions();
  }

  @override
  WorkspaceSessionDetail createSession(String title) {
    final id = 's-${_nextId()}';
    final now = DateTime.now();
    final session = WorkspaceSession(
      id: id,
      title: title,
      summary: seed ? _ai.sessionPreview(title) : title,
      purpose: title,
      preview: seed ? _ai.sessionPreview(title) : title,
      updatedAt: now,
      createdAt: now,
      status: SessionStatus.inProgress,
      messageCount: seed ? 1 : 0,
      durationLabel: 'New',
    );
    if (seed) {
      _messages[id] = [
        WorkspaceSessionMessage(
          id: 'm-${_nextId()}',
          author: MessageAuthor.ai,
          text: _ai.replyTo(title, title, 0),
          sentAt: now,
        ),
      ];
    }
    _sessions.insert(0, session);
    _event(
      TimelineEventType.session,
      'Chat started',
      description: title,
      at: now,
      refId: id,
    );
    return loadSessionDetail(id);
  }

  @override
  WorkspaceSessionDetail renameSession(String sessionId, String newTitle) {
    _sessions = [
      for (final s in _sessions)
        if (s.id == sessionId)
          s.copyWith(title: newTitle, updatedAt: DateTime.now())
        else
          s,
    ];
    return loadSessionDetail(sessionId);
  }

  @override
  WorkspaceSessionDetail sendMessage(String sessionId, String prompt) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final messages = List.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final userMessage = WorkspaceSessionMessage(
      id: 'm-${_nextId()}',
      author: MessageAuthor.user,
      text: prompt,
      sentAt: DateTime.now(),
    );
    final aiMessage = WorkspaceSessionMessage(
      id: 'm-${_nextId()}',
      author: MessageAuthor.ai,
      text: _ai.replyTo(session.title, prompt, messages.length + 1),
      sentAt: DateTime.now(),
    );
    _messages[sessionId] = [...messages, userMessage, aiMessage];
    final count = _messages[sessionId]!.length;
    _sessions = [
      for (final s in _sessions)
        if (s.id == sessionId)
          s.copyWith(
            messageCount: count,
            updatedAt: DateTime.now(),
            summary: _ai.sessionPreview(s.title),
          )
        else
          s,
    ];
    _event(
      TimelineEventType.session,
      'New message',
      description: prompt,
      refId: sessionId,
    );
    return loadSessionDetail(sessionId);
  }

  @override
  WorkspaceSessionDetail addSessionMessage(
    String sessionId,
    MessageAuthor author,
    String text,
  ) {
    final messages =
        List.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final message = WorkspaceSessionMessage(
      id: 'm-${_nextId()}',
      author: author,
      text: text,
      sentAt: DateTime.now(),
    );
    _messages[sessionId] = [...messages, message];
    final count = _messages[sessionId]!.length;
    _sessions = [
      for (final s in _sessions)
        if (s.id == sessionId)
          s.copyWith(messageCount: count, updatedAt: DateTime.now())
        else
          s,
    ];
    if (author == MessageAuthor.user) {
      _event(
        TimelineEventType.session,
        'New message',
        description: text,
        refId: sessionId,
      );
    }
    return loadSessionDetail(sessionId);
  }

  @override
  WorkspaceSessionDetail regenerateReply(String sessionId) {
    final messages = List.of(_messages[sessionId] ?? const <WorkspaceSessionMessage>[]);
    final last = messages.isEmpty ? null : messages.last;
    if (last != null && last.fromAi) {
      final replacement = WorkspaceSessionMessage(
        id: 'm-${_nextId()}',
        author: MessageAuthor.ai,
        text: _ai.replyTo(
          _sessions.firstWhere((s) => s.id == sessionId).title,
          last.text,
          messages.length + 1,
        ),
        sentAt: DateTime.now(),
      );
      _messages[sessionId] = [...messages.sublist(0, messages.length - 1), replacement];
    }
    return loadSessionDetail(sessionId);
  }

  // ---- Task mutations ----

  @override
  List<WorkspaceTask> setTaskDone(String taskId, bool done) {
    _tasks = [
      for (final t in _tasks)
        if (t.id == taskId)
          t.copyWith(
            done: done,
            subtasks: done && t.hasSubtasks
                ? [for (final s in t.subtasks) s.copyWith(done: true)]
                : t.subtasks,
          )
        else
          t,
    ];
    final task = _tasks.firstWhere((t) => t.id == taskId);
    _event(
      done ? TimelineEventType.milestone : TimelineEventType.task,
      done ? 'Task completed' : 'Task reopened',
      description: task.title,
      refId: taskId,
    );
    return loadTasks();
  }

  @override
  List<WorkspaceTask> setSubtaskDone(String taskId, int index, bool done) {
    _tasks = [
      for (final t in _tasks)
        if (t.id == taskId) _withSubtask(t, index, done) else t,
    ];
    return loadTasks();
  }

  WorkspaceTask _withSubtask(WorkspaceTask task, int index, bool done) {
    final subtasks = [
      for (var i = 0; i < task.subtasks.length; i++)
        i == index ? task.subtasks[i].copyWith(done: done) : task.subtasks[i],
    ];
    final allDone = subtasks.isNotEmpty && subtasks.every((s) => s.done);
    return task.copyWith(subtasks: subtasks, done: allDone);
  }

  @override
  List<WorkspaceTask> addTasks(List<WorkspaceTask> tasks) {
    _tasks = [...tasks, ..._tasks];
    for (final t in tasks) {
      _event(
        TimelineEventType.task,
        'Task added',
        description: t.title,
        refId: t.id,
      );
    }
    return loadTasks();
  }

  @override
  List<WorkspaceTask> deleteTask(String taskId) {
    _tasks = _tasks.where((t) => t.id != taskId).toList();
    return loadTasks();
  }

  @override
  List<WorkspaceTask> suggestTasks(String topic) {
    final titles = _ai.suggestedTaskTitles(topic);
    return [
      for (var i = 0; i < titles.length; i++)
        WorkspaceTask(
          id: 'ai-${_stableId(topic)}-$i',
          title: titles[i],
          done: false,
          priority: i == 0 ? TaskPriority.high : TaskPriority.medium,
          dueLabel: i == 0 ? 'Soon' : null,
          source: TaskSource.ai,
        ),
    ];
  }

  /// Deterministic string id derived from [topic] (no randomness).
  static int _stableId(String topic) {
    var hash = 0;
    for (final code in topic.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }

  // ---- File mutations ----

  @override
  List<WorkspaceFile> addFile(String name, AppFileType type) {
    final id = 'f-${_nextId()}';
    final file = WorkspaceFile(
      id: id,
      name: name,
      type: type,
      meta: 'Just added',
      createdAt: DateTime.now(),
    );
    _files.insert(0, file);
    _event(
      TimelineEventType.file,
      'File added',
      description: name,
      refId: id,
    );
    return loadFiles();
  }

  @override
  List<WorkspaceFile> deleteFile(String fileId) {
    _files = _files.where((f) => f.id != fileId).toList();
    return loadFiles();
  }

  @override
  List<WorkspaceFile> setFileFavourite(String fileId, bool favourite) {
    _files = [
      for (final f in _files)
        if (f.id == fileId) f.copyWith(favourite: favourite) else f,
    ];
    return loadFiles();
  }

  @override
  List<WorkspaceFile> setFilePinned(String fileId, bool pinned) {
    _files = [
      for (final f in _files)
        if (f.id == fileId) f.copyWith(pinned: pinned) else f,
    ];
    return loadFiles();
  }

  @override
  WorkspaceFile summarizeFile(String fileId) {
    final file = _files.firstWhere((f) => f.id == fileId);
    final updated = file.copyWith(
      summarized: true,
      summary: _ai.fileSummary(file.name, file.type.label),
    );
    _files = [
      for (final f in _files) f.id == fileId ? updated : f,
    ];
    _event(
      TimelineEventType.file,
      'File summarized',
      description: file.name,
      refId: fileId,
    );
    return updated;
  }

  // ---- Memory mutations ----

  @override
  List<WorkspaceMemory> addMemory(
    String title,
    String content,
    MemoryCategory category,
  ) {
    final id = 'm-${_nextId()}';
    final now = DateTime.now();
    final memory = WorkspaceMemory(
      id: id,
      title: title,
      content: content,
      category: category,
      source: 'Added manually · ${_shortDate(now)}',
      updatedAt: now,
    );
    _memories.insert(0, memory);
    _event(
      TimelineEventType.memory,
      'Memory saved',
      description: title,
      refId: id,
    );
    return loadMemories();
  }

  @override
  List<WorkspaceMemory> updateMemory(
    String memoryId, {
    String? title,
    String? content,
    MemoryCategory? category,
  }) {
    _memories = [
      for (final m in _memories)
        if (m.id == memoryId)
          m.copyWith(
            title: title,
            content: content,
            category: category,
            updatedAt: DateTime.now(),
          )
        else
          m,
    ];
    return loadMemories();
  }

  @override
  List<WorkspaceMemory> deleteMemory(String memoryId) {
    _memories = _memories.where((m) => m.id != memoryId).toList();
    return loadMemories();
  }

  @override
  List<WorkspaceMemory> setMemoryPinned(String memoryId, bool pinned) {
    _memories = [
      for (final m in _memories)
        if (m.id == memoryId) m.copyWith(pinned: pinned) else m,
    ];
    return loadMemories();
  }

  /// Neutral, non-fake briefing shown while an empty workspace has no content.
  static const List<BriefingLine> _emptyBriefing = [
    BriefingLine(
      text: 'Your workspace is ready - start a session or add a file.',
      icon: '\u2726',
    ),
  ];

  /// Neutral workspace record for the empty runtime (`seed: false`).
  static Workspace _newWorkspace() => Workspace(
        id: 'ws-default',
        name: 'My Workspace',
        description: '',
        emoji: '\u{1F5C2}\uFE0F',
        accent: MockWorkspaceData.workspace.accent,
        status: MockWorkspaceData.workspace.status,
        progressLabel: '0 tasks',
      );

  static String _shortDate(DateTime time) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[time.month - 1]} ${time.day}';
  }
}
