import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/errors/app_result.dart';
import '../data/repositories/workspace_repository.dart';
import '../domain/models/workspace.dart';
import '../domain/models/workspace_file.dart';
import '../domain/models/workspace_file_upload_request.dart';
import '../domain/models/workspace_memory.dart';
import '../domain/models/workspace_overview.dart';
import '../domain/models/workspace_search.dart';
import '../domain/models/workspace_session.dart';
import '../domain/models/workspace_session_detail.dart';
import '../domain/models/workspace_suggestion.dart';
import '../domain/models/workspace_task.dart';
import '../domain/models/workspace_timeline.dart';
import '../domain/services/briefing_deriver.dart';

/// Owns the workspace state the Overview, Sessions and Tasks tabs render.
///
/// A plain [ChangeNotifier] (no BLoC) — this screen is self-contained and has
/// no shared state, so a controller is the least ceremony. Reads flow from the
/// [WorkspaceRepository]; mutations delegate to the repository (so swapping in
/// a real backend never touches the UI) and then the controller re-syncs its
/// lists and notifies.
class WorkspaceController extends ChangeNotifier {
  WorkspaceController({
    required this.repository,
    this.loadDelay = const Duration(milliseconds: 300),
  }) {
    _workspace = repository.getWorkspace();
    _overview = repository.loadOverview();
    _sessions = const [];
    _tasks = const [];
    _files = const [];
    _memories = const [];
    _timeline = const [];
    _suggestedTasks = const [];
    _initialLoadCompleter = Completer<void>();
    _initialLoad();
  }

  final WorkspaceRepository repository;
  final Duration loadDelay;
  final Duration _searchDelay = const Duration(milliseconds: 250);

  Workspace? _workspace;
  late WorkspaceOverview _overview;
  List<WorkspaceSession> _sessions = const [];
  List<WorkspaceTask> _tasks = const [];
  List<WorkspaceFile> _files = const [];
  List<WorkspaceMemory> _memories = const [];
  List<TimelineEvent> _timeline = const [];
  List<WorkspaceTask> _suggestedTasks = const [];
  WorkspaceSearchResults _searchResults = const WorkspaceSearchResults();
  bool _searching = false;
  bool _loading = false;
  bool _isUploading = false;
  String? _uploadError;
  bool _disposed = false;
  Completer<void>? _initialLoadCompleter;

  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  /// Set by the screen so the controller can surface transient notices
  /// (SnackBars) without holding a BuildContext.
  void Function(String message)? onNotice;

  /// Set by the screen to navigate into a session detail screen.
  void Function(WorkspaceSession session)? onOpenSession;

  /// Set by the screen to switch to a pinned tab.
  VoidCallback? onSeeAllSessions;
  VoidCallback? onSeeAllTasks;
  VoidCallback? onSeeAllFiles;
  VoidCallback? onSeeAllMemory;
  VoidCallback? onSearch;

  Workspace get workspace => _workspace ?? _overview.workspace;

  WorkspaceOverview get overview => _overview;

  List<WorkspaceSession> get sessions => _sessions;

  List<WorkspaceTask> get tasks => _tasks;

  List<WorkspaceFile> get files => _files;

  List<WorkspaceMemory> get memories => _memories;

  List<TimelineEvent> get timeline => _timeline;

  List<WorkspaceTask> get suggestedTasks => _suggestedTasks;

  /// Latest search results; empty until [search] is called.
  WorkspaceSearchResults get searchResults => _searchResults;

  bool get isSearching => _searching;

  bool get isLoading => _loading;

  /// Completes once the simulated initial load finishes.
  Future<void> get initialLoad => _initialLoadCompleter?.future ?? Future.value();

  // ---- Loading ----

  Future<void> _initialLoad() async {
    _loading = true;
    await Future<void>.delayed(loadDelay);
    if (_disposed) return;
    _loadAll();
    _loading = false;
    _initialLoadCompleter?.complete();
    notifyListeners();
  }

  /// Reloads everything from the repository (pull-to-refresh, returning from
  /// a detail screen).
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(loadDelay);
    if (_disposed) return;
    _loadAll();
    _loading = false;
    notifyListeners();
  }

  void _loadAll() {
    _sessions = repository.loadSessions();
    _tasks = repository.loadTasks();
    _files = repository.loadFiles();
    _memories = repository.loadMemories();
    _timeline = repository.loadTimeline();
    _overview = repository.loadOverview();
    _workspace = repository.getWorkspace();
    _rebuildOverview();
  }

  /// Recomputes workspace progress and rebuilds the overview aggregate from
  /// the controller's own lists so every surface stays in sync. Briefing is
  /// recomputed from current workspace state (tasks/sessions/files/memories/
  /// timeline) via [BriefingDeriver] — no longer preserved from previous
  /// overview.
  void _rebuildOverview() {
    final activeTasks = _tasks.where((t) => !t.archived).toList();
    final activeSessions = _sessions.where((s) => !s.archived).toList();
    final doneCount = activeTasks.where((t) => t.done).length;
    _workspace = _copyWorkspace(
      progress: activeTasks.isEmpty ? 0 : doneCount / activeTasks.length,
      progressLabel: '$doneCount of ${activeTasks.length} tasks',
      taskCount: activeTasks.length,
      taskDone: doneCount,
    );
    final List<BriefingLine> derivedBriefing = BriefingDeriver.derive(
      workspace: _workspace ?? _overview.workspace,
      tasks: activeTasks,
      sessions: activeSessions,
      files: _files,
      memories: _memories,
      timeline: _timeline,
    );
    _overview = WorkspaceOverview(
      workspace: _workspace ?? _overview.workspace,
      briefing: derivedBriefing,
      continueTitle: _overview.continueTitle,
      continueSnippet: _overview.continueSnippet,
      continueProgress: _overview.continueProgress,
      continueProgressLabel: _overview.continueProgressLabel,
      tasks: activeTasks,
      sessions: activeSessions,
      files: _files,
      memories: _memories,
      suggestions: _overview.suggestions,
    );
  }

  // ---- Tasks ----

  void toggleTask(WorkspaceTask task, bool done) {
    _tasks = repository.setTaskDone(task.id, done);
    _rebuildOverview();
    notifyListeners();
  }

  void toggleSubtask(WorkspaceTask task, int index, bool done) {
    _tasks = repository.setSubtaskDone(task.id, index, done);
    _rebuildOverview();
    notifyListeners();
  }

  void deleteTask(WorkspaceTask task) {
    _tasks = repository.deleteTask(task.id);
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Task "${task.title}" removed');
  }

  void generateSuggestions() {
    _suggestedTasks = repository.suggestTasks('this week');
    notifyListeners();
  }

  void acceptSuggestion(WorkspaceTask task) {
    _tasks = repository.addTasks([task]);
    _suggestedTasks = _suggestedTasks.where((t) => t.id != task.id).toList();
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Added "${task.title}" to the task list');
  }

  void dismissSuggestion(WorkspaceTask task) {
    _suggestedTasks = _suggestedTasks.where((t) => t.id != task.id).toList();
    notifyListeners();
  }

  // ---- Sessions ----

  void pinSession(WorkspaceSession session) {
    _sessions = repository.setSessionPinned(session.id, !session.pinned);
    _rebuildOverview();
    notifyListeners();
    onNotice?.call(session.pinned ? 'Session unpinned' : 'Session pinned');
  }

  void archiveSession(WorkspaceSession session) {
    _sessions = repository.setSessionArchived(session.id, !session.archived);
    _rebuildOverview();
    notifyListeners();
    onNotice?.call(
      session.archived ? 'Session restored' : 'Session archived',
    );
  }

  void deleteSession(WorkspaceSession session) {
    _sessions = repository.deleteSession(session.id);
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Session "${session.title}" deleted');
  }

  Future<WorkspaceSessionDetail> createSession(String title) async {
    final detail = repository.createSession(title);
    _sessions = repository.loadSessions();
    _rebuildOverview();
    notifyListeners();
    return detail;
  }

  // ---- Files ----

  void addFile(String name, AppFileType type) {
    _files = repository.addFile(name, type);
    _timeline = repository.loadTimeline();
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Added "$name" to the workspace');
  }

  /// Real file upload — validates via [WorkspaceFileUploadRequest] and
  /// orchestrates Storage → Firestore with rollback. Prevents duplicate
  /// uploads while one is in flight.
  Future<AppResult<WorkspaceFile>> uploadWorkspaceFile(WorkspaceFileUploadRequest request) async {
    if (_isUploading) {
      const AppResult<WorkspaceFile> err = Failure(ValidationError('Upload already in progress'));
      onNotice?.call('Upload already in progress');
      return err;
    }
    _isUploading = true;
    _uploadError = null;
    notifyListeners();
    final AppResult<WorkspaceFile> result = await repository.uploadWorkspaceFile(request);
    if (result is Success<WorkspaceFile>) {
      _files = repository.loadFiles();
      _timeline = repository.loadTimeline();
      _rebuildOverview();
      onNotice?.call('Added "${request.fileName}"');
    } else if (result is Failure<WorkspaceFile>) {
      _uploadError = result.error.message;
      onNotice?.call('Upload failed: ${result.error.message}');
    }
    _isUploading = false;
    notifyListeners();
    return result;
  }

  /// Opens a workspace file via its Storage path → download URL.
  /// Returns the URL on success for the UI to launch.
  Future<AppResult<String>> openWorkspaceFile(WorkspaceFile file) async {
    final AppResult<String> result = await repository.getFileDownloadUrl(file.id);
    if (result is Failure<String>) {
      onNotice?.call('Open failed: ${result.error.message}');
    }
    return result;
  }

  Future<void> deleteFile(WorkspaceFile file) async {
    final AppResult<void> result = await repository.deleteFile(file.id);
    if (result is Failure<void>) {
      _files = repository.loadFiles();
      _timeline = repository.loadTimeline();
      _rebuildOverview();
      notifyListeners();
      onNotice?.call('Delete failed: ${result.error.message}');
      return;
    }
    _files = repository.loadFiles();
    _timeline = repository.loadTimeline();
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('File "${file.name}" removed');
  }

  void toggleFileFavourite(WorkspaceFile file) {
    _files = repository.setFileFavourite(file.id, !file.favourite);
    notifyListeners();
  }

  void toggleFilePinned(WorkspaceFile file) {
    _files = repository.setFilePinned(file.id, !file.pinned);
    notifyListeners();
    onNotice?.call(file.pinned ? 'File unpinned' : 'File pinned');
  }

  Future<void> summarizeFile(WorkspaceFile file) async {
    _files = [
      for (final f in _files)
        if (f.id == file.id) f.copyWith(summarized: true) else f,
    ];
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_disposed) return;
    final updated = repository.summarizeFile(file.id);
    _files = [
      for (final f in _files) f.id == updated.id ? updated : f,
    ];
    _timeline = repository.loadTimeline();
    notifyListeners();
    onNotice?.call('Summary ready for "${updated.name}"');
  }

  // ---- Memory ----

  void addMemory(String title, String content, MemoryCategory category) {
    _memories = repository.addMemory(title, content, category);
    _timeline = repository.loadTimeline();
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Memory saved');
  }

  void updateMemory(
    WorkspaceMemory memory, {
    String? title,
    String? content,
    MemoryCategory? category,
  }) {
    _memories = repository.updateMemory(
      memory.id,
      title: title,
      content: content,
      category: category,
    );
    notifyListeners();
    onNotice?.call('Memory updated');
  }

  void deleteMemory(WorkspaceMemory memory) {
    _memories = repository.deleteMemory(memory.id);
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Memory removed');
  }

  void toggleMemoryPinned(WorkspaceMemory memory) {
    _memories = repository.setMemoryPinned(memory.id, !memory.pinned);
    notifyListeners();
    onNotice?.call(memory.pinned ? 'Memory unpinned' : 'Memory pinned');
  }

  // ---- Briefing & search ----

  void regenerateBriefing() {
    final List<BriefingLine> lines = repository.regenerateBriefing();
    _overview = WorkspaceOverview(
      workspace: _overview.workspace,
      briefing: lines,
      continueTitle: _overview.continueTitle,
      continueSnippet: _overview.continueSnippet,
      continueProgress: _overview.continueProgress,
      continueProgressLabel: _overview.continueProgressLabel,
      tasks: _overview.tasks,
      sessions: _overview.sessions,
      files: _overview.files,
      memories: _overview.memories,
      suggestions: _overview.suggestions,
    );
    notifyListeners();
  }

  void dismissOverviewSuggestion(WorkspaceSuggestion suggestion) {
    final remaining = _overview.suggestions
        .where((s) => s.id != suggestion.id)
        .toList();
    _overview = WorkspaceOverview(
      workspace: _overview.workspace,
      briefing: _overview.briefing,
      continueTitle: _overview.continueTitle,
      continueSnippet: _overview.continueSnippet,
      continueProgress: _overview.continueProgress,
      continueProgressLabel: _overview.continueProgressLabel,
      tasks: _overview.tasks,
      sessions: _overview.sessions,
      files: _overview.files,
      memories: _overview.memories,
      suggestions: remaining,
    );
    notifyListeners();
  }

  /// Runs a workspace-wide search; updates [searchResults].
  Future<void> search(String query) async {
    final q = query.trim();
    _searching = true;
    notifyListeners();
    await Future<void>.delayed(_searchDelay);
    if (_disposed) return;
    _searchResults = repository.search(q);
    _searching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = const WorkspaceSearchResults();
    _searching = false;
    notifyListeners();
  }

  // ---- Workspace record ----

  void togglePin() {
    _workspace = _copyWorkspace(pinned: !workspace.pinned);
    notifyListeners();
  }

  void toggleFavourite() {
    _workspace = _copyWorkspace(favourite: !workspace.favourite);
    notifyListeners();
  }

  /// Turns an Overview AI suggestion into a task.
  void applySuggestion(WorkspaceSuggestion suggestion) {
    final task = WorkspaceTask(
      id: 'task-${suggestion.id}',
      title: suggestion.title,
      done: false,
      priority: TaskPriority.medium,
      source: TaskSource.ai,
    );
    _tasks = repository.addTasks([task]);
    _rebuildOverview();
    notifyListeners();
    onNotice?.call('Added "${suggestion.title}" to the task list');
  }

  void showPlaceholder(String section) {
    onNotice?.call('"$section" is coming in the next build');
  }

  Workspace _copyWorkspace({
    double? progress,
    String? progressLabel,
    int? taskCount,
    int? taskDone,
    bool? pinned,
    bool? favourite,
  }) {
    return Workspace(
      id: workspace.id,
      name: workspace.name,
      description: workspace.description,
      emoji: workspace.emoji,
      accent: workspace.accent,
      cover: workspace.cover,
      status: workspace.status,
      progress: progress ?? workspace.progress,
      progressLabel: progressLabel ?? workspace.progressLabel,
      pinned: pinned ?? workspace.pinned,
      favourite: favourite ?? workspace.favourite,
      taskCount: taskCount ?? workspace.taskCount,
      taskDone: taskDone ?? workspace.taskDone,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
