import 'workspace_file.dart';
import 'workspace_memory.dart';
import 'workspace_session.dart';
import 'workspace_task.dart';
import 'workspace_timeline.dart';

/// Grouped results for a workspace-wide search.
class WorkspaceSearchResults {
  const WorkspaceSearchResults({
    this.sessions = const [],
    this.tasks = const [],
    this.files = const [],
    this.memories = const [],
    this.timeline = const [],
  });

  final List<WorkspaceSession> sessions;
  final List<WorkspaceTask> tasks;
  final List<WorkspaceFile> files;
  final List<WorkspaceMemory> memories;
  final List<TimelineEvent> timeline;

  int get total => sessions.length + tasks.length + files.length +
      memories.length + timeline.length;

  bool get isEmpty => total == 0;
}
