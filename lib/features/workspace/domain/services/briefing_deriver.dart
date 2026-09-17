import '../models/workspace.dart';
import '../models/workspace_file.dart';
import '../models/workspace_memory.dart';
import '../models/workspace_overview.dart';
import '../models/workspace_session.dart';
import '../models/workspace_task.dart';
import '../models/workspace_timeline.dart';

/// Pure, deterministic briefing derivation — no Firestore, no UI, no AI.
///
/// Takes the current workspace snapshot (already loaded from the repository)
/// and produces 1–4 useful [BriefingLine]s for `DailyBriefingCard`.
///
/// Priority:
///  1. Empty readiness (workspace empty, no signals)
///  2. Task progress
///  3. Recent session activity
///  4. Recent file activity
///  5. Memory/activity count
///
/// Keeps output to 1–4 lines, highlight only for the most actionable line.
///
/// Sorted-input contract: callers may pass lists in any order; the deriver
/// explicitly selects the most recent session/file/memory/timeline entry by
/// its timestamp (`updatedAt`/`createdAt`/`occurredAt`) so output is
/// deterministic regardless of repository cache ordering.
final class BriefingDeriver {
  BriefingDeriver._();

  /// Derive briefing from real workspace state.
  ///
  /// All inputs are the repository/controller's current cached lists
  /// (already filtered for archived where applicable by the caller). Order
  /// does not matter — the deriver selects the most recent entry by timestamp.
  static List<BriefingLine> derive({
    required Workspace workspace,
    required List<WorkspaceTask> tasks,
    required List<WorkspaceSession> sessions,
    required List<WorkspaceFile> files,
    required List<WorkspaceMemory> memories,
    required List<TimelineEvent> timeline,
  }) {
    final bool hasWorkspace = workspace.id.isNotEmpty && workspace.name.isNotEmpty;
    final bool hasTasks = tasks.isNotEmpty;
    final bool hasSessions = sessions.isNotEmpty;
    final bool hasFiles = files.isNotEmpty;
    final bool hasMemories = memories.isNotEmpty;
    final bool hasTimeline = timeline.isNotEmpty;

    // Empty readiness — same copy as MockWorkspaceService._emptyBriefing so
    // empty_seed_test and OverviewTab empty state keep passing.
    final bool isEmpty = !hasWorkspace && !hasTasks && !hasSessions && !hasFiles && !hasMemories && !hasTimeline;
    // Also treat “workspace default but nothing else” as empty (seed:false case
    // produces ws-default/My Workspace with zero items — still readiness).
    final bool isEffectivelyEmpty = !hasTasks && !hasSessions && !hasFiles && !hasMemories && !hasTimeline;
    if (isEmpty || isEffectivelyEmpty) {
      return const [
        BriefingLine(text: 'Your workspace is ready - start a session or add a file.', icon: '✦'),
      ];
    }

    final List<BriefingLine> lines = [];

    // 1. Task progress — always useful if tasks exist
    if (hasTasks) {
      final int total = tasks.length;
      final int done = tasks.where((t) => t.done).length;
      if (done == total && total > 0) {
        lines.add(BriefingLine(
          text: 'All $total tasks completed — great progress today.',
          icon: '✓',
          highlight: true,
        ));
      } else if (total > 0) {
        final int pending = total - done;
        // Keep the original mock phrase fragment so task-count tests remain green if they check contains
        final String pendingText = pending == 1 ? '1 task remaining' : '$pending tasks remaining';
        lines.add(BriefingLine(
          text: '$done of $total tasks done — $pendingText.',
          icon: '✓',
          highlight: true,
        ));
      }
    }

    // 2. Recent session — most recent by updatedAt (deterministic, not cache order)
    if (hasSessions) {
      final WorkspaceSession recent = _mostRecentSession(sessions);
      final String title = recent.title.trim().isEmpty ? 'Untitled session' : recent.title.trim();
      // Truncate to first line / 48 chars to keep card compact (matches Previous UI)
      final String short = title.length > 48 ? '${title.substring(0, 48)}…' : title;
      lines.add(BriefingLine(
        text: 'Recent session: $short',
        icon: '💬',
      ));
    }

    // 3. Recent file — most recent by createdAt (deterministic)
    if (hasFiles) {
      final WorkspaceFile recent = _mostRecentFile(files);
      final String name = recent.name.trim().isEmpty ? 'file' : recent.name.trim();
      lines.add(BriefingLine(
        text: 'Latest file: $name',
        icon: '📄',
      ));
    }

    // 4. Memory — neutral count representing persisted state (not "Memory saved: title" merely because it exists)
    if (hasMemories) {
      lines.add(BriefingLine(
        text: '${memories.length} ${memories.length == 1 ? 'memory' : 'memories'} saved',
        icon: '🧠',
      ));
    } else if (hasTimeline && lines.length < 4) {
      // Fallback: show recent timeline activity if no memories
      final TimelineEvent recent = _mostRecentTimeline(timeline);
      // Use timeline title as activity hint, keep generic
      lines.add(BriefingLine(
        text: recent.title,
        icon: recent.type == TimelineEventType.session
            ? '💬'
            : recent.type == TimelineEventType.file
                ? '📄'
                : recent.type == TimelineEventType.task || recent.type == TimelineEventType.milestone
                    ? '✓'
                    : '✦',
      ));
    }

    // Keep to 1–4 useful lines, deterministic order: tasks → session → file → memory/timeline
    if (lines.isEmpty) {
      // No signal matched but not empty workspace (e.g., workspace has name/description only)
      return const [
        BriefingLine(text: 'Your workspace is ready - start a session or add a file.', icon: '✦'),
      ];
    }
    if (lines.length > 4) return lines.sublist(0, 4);
    return lines;
  }

  static WorkspaceSession _mostRecentSession(List<WorkspaceSession> list) {
    WorkspaceSession best = list.first;
    for (final s in list.skip(1)) {
      if (s.updatedAt.isAfter(best.updatedAt)) best = s;
    }
    return best;
  }

  static WorkspaceFile _mostRecentFile(List<WorkspaceFile> list) {
    WorkspaceFile best = list.first;
    DateTime bestTime = best.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    for (final f in list.skip(1)) {
      final DateTime t = f.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (t.isAfter(bestTime)) {
        best = f;
        bestTime = t;
      }
    }
    return best;
  }

  static TimelineEvent _mostRecentTimeline(List<TimelineEvent> list) {
    TimelineEvent best = list.first;
    for (final e in list.skip(1)) {
      if (e.occurredAt.isAfter(best.occurredAt)) best = e;
    }
    return best;
  }
}
