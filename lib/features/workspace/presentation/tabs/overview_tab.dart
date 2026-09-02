import 'package:flutter/material.dart';
import '../../../../core/design_system/design_system.dart' hide ContinueCard;
import '../../domain/models/workspace.dart';
import '../../widgets/files/file_detail_sheet.dart';
import '../../widgets/sections/ai_suggestions.dart';
import '../../widgets/sections/continue_card.dart';
import '../../widgets/sections/daily_briefing_card.dart';
import '../../widgets/sections/memory_strip.dart';
import '../../widgets/sections/recent_files_preview.dart';
import '../../widgets/sections/recent_sessions_preview.dart';
import '../../widgets/sections/tasks_preview.dart';
import '../workspace_controller.dart';

/// Overview tab — the landing view of a workspace.
///
/// Renders the live overview state from [WorkspaceController]. Every section
/// already works against the mock repository; Sprint 2 swaps in real data.
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.controller, required this.workspace});

  final WorkspaceController controller;
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final spacing = context.appSpacing;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final overview = controller.overview;
        return CustomScrollView(
          key: const PageStorageKey('workspace-overview'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.md,
                spacing.md,
                spacing.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Home',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: spacing.md),
                  DailyBriefingCard(
                    lines: overview.briefing,
                    onRefresh: controller.regenerateBriefing,
                  ),
                  SizedBox(height: spacing.md),
                  if (overview.continueTitle case final continueTitle?) ...[
                    ContinueCard(
                      title: continueTitle,
                      snippet: overview.continueSnippet,
                      progress: overview.continueProgress,
                      progressLabel: overview.continueProgressLabel,
                      onContinue: () => controller.showPlaceholder(continueTitle),
                    ),
                    SizedBox(height: spacing.md),
                  ],
                  AiSuggestions(
                    suggestions: overview.suggestions,
                    onApply: controller.applySuggestion,
                    onDismiss: controller.dismissOverviewSuggestion,
                  ),
                  SizedBox(height: spacing.md),
                  TasksPreview(
                    tasks: overview.tasks,
                    onTaskToggle: controller.toggleTask,
                    onSeeAll: () {
                      final cb = controller.onSeeAllTasks;
                      if (cb != null) {
                        cb();
                      } else {
                        controller.showPlaceholder('Tasks');
                      }
                    },
                  ),
                  SizedBox(height: spacing.md),
                  RecentSessionsPreview(
                    sessions: overview.sessions,
                    onOpen: (s) => controller.onOpenSession?.call(s),
                    onSeeAll: () {
                      final cb = controller.onSeeAllSessions;
                      if (cb != null) {
                        cb();
                      } else {
                        controller.showPlaceholder('Sessions');
                      }
                    },
                  ),
                  SizedBox(height: spacing.md),
                  RecentFilesPreview(
                    files: overview.files,
                    onOpen: (f) => showFileDetailSheet(context, controller, f),
                    onSeeAll: () {
                      final cb = controller.onSeeAllFiles;
                      if (cb != null) {
                        cb();
                      } else {
                        controller.showPlaceholder('Files');
                      }
                    },
                  ),
                  SizedBox(height: spacing.md),
                  MemoryStrip(
                    entries: overview.memories,
                    onOpenAll: () {
                      final cb = controller.onSeeAllMemory;
                      if (cb != null) {
                        cb();
                      } else {
                        controller.showPlaceholder('Memory');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
