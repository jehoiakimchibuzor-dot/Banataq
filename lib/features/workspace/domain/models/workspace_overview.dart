import 'workspace.dart';
import 'workspace_file.dart';
import 'workspace_memory.dart';
import 'workspace_session.dart';
import 'workspace_suggestion.dart';
import 'workspace_task.dart';

/// One line in the daily briefing.
class BriefingLine {
  const BriefingLine({
    required this.text,
    this.icon,
    this.highlight = false,
  });

  final String text;

  /// Optional leading icon (theme-driven in the widget).
  final String? icon;
  final bool highlight;
}

/// The aggregate of everything the Overview tab renders.
class WorkspaceOverview {
  const WorkspaceOverview({
    required this.workspace,
    this.briefing = const [],
    this.continueTitle,
    this.continueSnippet,
    this.continueProgress,
    this.continueProgressLabel,
    this.tasks = const [],
    this.sessions = const [],
    this.files = const [],
    this.memories = const [],
    this.suggestions = const [],
  });

  final Workspace workspace;
  final List<BriefingLine> briefing;
  final String? continueTitle;
  final String? continueSnippet;
  final double? continueProgress;
  final String? continueProgressLabel;
  final List<WorkspaceTask> tasks;
  final List<WorkspaceSession> sessions;
  final List<WorkspaceFile> files;
  final List<WorkspaceMemory> memories;
  final List<WorkspaceSuggestion> suggestions;
}
