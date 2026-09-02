import 'workspace_file.dart';
import 'workspace_session.dart';
import 'workspace_session_message.dart';
import 'workspace_task.dart';

/// Everything the Session Details screen renders for one session:
/// the conversation, AI-generated summaries, action items, key facts and the
/// linked files/tasks.
class WorkspaceSessionDetail {
  const WorkspaceSessionDetail({
    required this.session,
    this.messages = const [],
    this.aiSummary,
    this.actionItems = const [],
    this.keyFacts = const [],
    this.linkedFiles = const [],
    this.linkedTasks = const [],
  });

  final WorkspaceSession session;
  final List<WorkspaceSessionMessage> messages;

  /// AI-written paragraph summarising the session.
  final String? aiSummary;
  final List<String> actionItems;
  final List<String> keyFacts;
  final List<WorkspaceFile> linkedFiles;
  final List<WorkspaceTask> linkedTasks;

  WorkspaceSessionDetail copyWith({WorkspaceSession? session}) {
    return WorkspaceSessionDetail(
      session: session ?? this.session,
      messages: messages,
      aiSummary: aiSummary,
      actionItems: actionItems,
      keyFacts: keyFacts,
      linkedFiles: linkedFiles,
      linkedTasks: linkedTasks,
    );
  }
}
