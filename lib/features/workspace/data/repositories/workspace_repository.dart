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
