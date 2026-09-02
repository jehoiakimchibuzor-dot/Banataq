import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/models/workspace.dart';
import '../../domain/models/workspace_file.dart';
import '../../domain/models/workspace_memory.dart';
import '../../domain/models/workspace_overview.dart';
import '../../domain/models/workspace_session.dart';
import '../../domain/models/workspace_suggestion.dart';
import '../../domain/models/workspace_task.dart';

/// Mock data for the Workspace shell.
///
/// This is the single source of fake workspace content so the UI can be
/// reviewed before any real data source exists. No business logic here.
///
/// Conversation text is seeded as *user prompts* only — the AI replies are
/// generated through `MockWorkspaceAIService` when the mock service is built,
/// so every piece of "intelligence" flows through the one seam.
abstract final class MockWorkspaceData {
  static final Workspace workspace = Workspace(
    id: 'ws-gana',
    name: 'GANO',
    description: 'School & career — university admission project.',
    emoji: '🚀',
    accent: const Color(0xFFE2C477),
    status: WorkspaceStatus.active,
    progress: 0.4,
    progressLabel: '2 of 5 tasks',
    pinned: true,
    favourite: true,
    taskCount: 5,
    taskDone: 2,
  );

  static const List<BriefingLine> briefing = [
    BriefingLine(
      text: 'You worked here yesterday for ~40 minutes.',
      icon: '✳',
    ),
    BriefingLine(
      text: '2 of 5 tasks done — supplier decision is the blocker.',
      icon: '✓',
      highlight: true,
    ),
    BriefingLine(
      text: '1 new file added since your last visit.',
      icon: '📄',
    ),
    BriefingLine(text: 'Alhaji Musa\'s quote arrives tomorrow.'),
  ];

  /// Alternate briefing variants the mock cycles through on regenerate.
  static const List<List<BriefingLine>> briefingVariants = [
    [
      BriefingLine(
        text: 'Focus on the supplier decision today — everything else is on track.',
        icon: '★',
        highlight: true,
      ),
      BriefingLine(text: 'Admission checklist is fully reviewed.'),
      BriefingLine(text: 'No new files since your last visit.'),
    ],
    [
      BriefingLine(
        text: 'Three open tasks are due soon, one is overdue.',
        icon: '⚠',
        highlight: true,
      ),
      BriefingLine(text: 'Your last session was the supplier pricing breakdown.'),
      BriefingLine(text: '2 memories were updated this week.'),
    ],
  ];

  static const String continueTitle = 'Compare the three supplier quotes';

  static const String continueSnippet =
      'You were drafting the supplier decision table. Pick the best '
      'pricing option before Friday.';

  static const double continueProgress = 0.5;

  static const String continueProgressLabel = '3 of 6';

  static final List<WorkspaceSession> sessions = [
    WorkspaceSession(
      id: 's1',
      title: 'Supplier pricing breakdown',
      summary:
          'Compared 3 quotes for the packaging order — still deciding '
          'between vendor B and C.',
      purpose: 'Compare the three supplier quotes',
      preview:
          'Three quotes compared; leaning towards vendor B for this batch.',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: SessionStatus.inProgress,
      messageCount: 4,
      durationLabel: '24m',
      pinned: true,
      linkedFileIds: const ['f1', 'f2'],
      linkedTaskIds: const ['t1', 't2'],
    ),
    WorkspaceSession(
      id: 's2',
      title: 'Admission requirements',
      summary: 'Listed JAMB subject requirements for the course.',
      purpose: 'List the JAMB requirements for the course',
      preview: 'Requirements captured; documents list is next.',
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      status: SessionStatus.completed,
      messageCount: 2,
      durationLabel: '12m',
      pinned: true,
      linkedFileIds: const ['f3'],
      linkedTaskIds: const ['t5'],
    ),
    WorkspaceSession(
      id: 's3',
      title: 'School budget draft',
      summary: 'Started a simple budget table for fees + extras.',
      purpose: 'Draft a budget table for fees and extras',
      preview: 'First draft of the school budget is ready to refine.',
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      status: SessionStatus.completed,
      messageCount: 2,
      durationLabel: '9m',
      linkedFileIds: const ['f4'],
      linkedTaskIds: const ['t4'],
    ),
    WorkspaceSession(
      id: 's4',
      title: 'Suppliers follow-up',
      summary: 'Followed up with vendors who had not replied yet.',
      purpose: 'Follow up with the vendors who have not replied',
      preview: 'Follow-ups queued; replies expected tomorrow.',
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      status: SessionStatus.completed,
      messageCount: 2,
      durationLabel: '6m',
      linkedTaskIds: const ['t1'],
    ),
    WorkspaceSession(
      id: 's5',
      title: 'Application timeline',
      summary: 'Mapped out the application timeline for the course.',
      purpose: 'Plan the application timeline',
      preview: 'Timeline drafted; first milestone is this week.',
      updatedAt: DateTime.now().subtract(const Duration(days: 6)),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      status: SessionStatus.idle,
      messageCount: 2,
      durationLabel: '15m',
      linkedFileIds: const ['f2'],
      linkedTaskIds: const ['t6'],
    ),
  ];

  static final List<WorkspaceTask> tasks = [
    WorkspaceTask(
      id: 't1',
      title: 'Compare supplier quotes',
      done: false,
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 1)),
      contextLabel: 'Supplier',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      linkedSessionIds: const ['s1', 's4'],
      linkedFileIds: const ['f1'],
    ),
    WorkspaceTask(
      id: 't2',
      title: 'Draft the decision table',
      done: false,
      priority: TaskPriority.medium,
      contextLabel: 'Supplier',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      linkedSessionIds: const ['s1'],
    ),
    WorkspaceTask(
      id: 't3',
      title: 'Send price list to Alhaji Musa',
      done: false,
      priority: TaskPriority.high,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      contextLabel: 'Supplier',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      linkedSessionIds: const ['s4'],
    ),
    WorkspaceTask(
      id: 't4',
      title: 'Update school budget sheet',
      done: true,
      priority: TaskPriority.low,
      dueDate: DateTime.now().subtract(const Duration(days: 2)),
      contextLabel: 'Budget',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      linkedSessionIds: const ['s3'],
      linkedFileIds: const ['f4'],
    ),
    WorkspaceTask(
      id: 't5',
      title: 'Review admission checklist',
      done: true,
      priority: TaskPriority.medium,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      contextLabel: 'Admission',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      linkedSessionIds: const ['s2'],
    ),
    WorkspaceTask(
      id: 't6',
      title: 'Book the entrance exam slot',
      done: false,
      priority: TaskPriority.high,
      dueDate: DateTime.now(),
      contextLabel: 'Admission',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      linkedSessionIds: const ['s5'],
      subtasks: const [
        WorkspaceSubtask(id: 't6s1', title: 'Confirm the exam date', done: true),
        WorkspaceSubtask(id: 't6s2', title: 'Pay the exam fee', done: false),
      ],
    ),
    WorkspaceTask(
      id: 't7',
      title: 'Pick a campus tour date',
      done: false,
      priority: TaskPriority.medium,
      dueDate: DateTime.now().add(const Duration(days: 5)),
      contextLabel: 'School',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    WorkspaceTask(
      id: 't8',
      title: 'Read the admission brochure',
      done: true,
      priority: TaskPriority.low,
      dueDate: DateTime.now().subtract(const Duration(days: 4)),
      contextLabel: 'Admission',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    WorkspaceTask(
      id: 't9',
      title: 'Submit the signed form',
      done: false,
      priority: TaskPriority.high,
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      contextLabel: 'Admission',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      linkedSessionIds: const ['s2'],
      linkedFileIds: const ['f3'],
    ),
  ];

  static const List<WorkspaceFile> files = [
    WorkspaceFile(
      id: 'f1',
      name: 'suppliers_quote.xlsx',
      type: AppFileType.sheet,
      meta: '24 KB · Updated 2h ago',
      summarized: true,
    ),
    WorkspaceFile(
      id: 'f2',
      name: 'gana_pitch_deck.pdf',
      type: AppFileType.pdf,
      meta: '1.2 MB · Yesterday',
      summarized: true,
    ),
    WorkspaceFile(
      id: 'f3',
      name: 'requirements_list.docx',
      type: AppFileType.document,
      meta: '48 KB · Mon',
    ),
    WorkspaceFile(
      id: 'f4',
      name: 'campus_map.png',
      type: AppFileType.image,
      meta: '380 KB · Sun',
    ),
  ];

  static const List<WorkspaceMemory> memories = [
    WorkspaceMemory(
      id: 'm1',
      title: 'Preferred currency',
      content: 'Always present supplier quotes in Naira.',
      category: MemoryCategory.preferences,
      source: 'From session · Aug 1',
      pinned: true,
    ),
    WorkspaceMemory(
      id: 'm2',
      title: 'Alhaji Musa approves orders',
      content: 'GANO packaging orders need Alhaji Musa\'s sign-off.',
      category: MemoryCategory.contacts,
      source: 'From session · Jul 29',
      pinned: true,
    ),
    WorkspaceMemory(
      id: 'm3',
      title: 'Deadline — Friday',
      content: 'Supplier decision due before Friday.',
      category: MemoryCategory.goals,
      confidence: MemoryConfidence.recurring,
      source: 'From session · Aug 2',
    ),
  ];

  static const List<WorkspaceSuggestion> suggestions = [
    WorkspaceSuggestion(
      id: 'sug1',
      title: 'Draft the supplier decision table',
      description:
          'I can turn the three quotes into a comparison table you can send.',
      icon: Icons.table_chart_rounded,
    ),
    WorkspaceSuggestion(
      id: 'sug2',
      title: 'Summarize this week',
      description:
          'Here\'s what happened across GANO this week, in one page.',
      icon: Icons.auto_awesome_rounded,
    ),
    WorkspaceSuggestion(
      id: 'sug3',
      title: 'Prepare Friday\'s check-in',
      description: 'Draft talking points for the supplier call.',
      icon: Icons.fact_check_rounded,
    ),
  ];

  /// One or more opening user prompts per session. The mock service expands
  /// these into full user + AI turns through the AI service.
  static const Map<String, List<String>> sessionPrompts = {
    's1': [
      'Compare the three supplier quotes we received.',
      'Which option is best for a small batch?',
    ],
    's2': ['What are the admission requirements for the course?'],
    's3': ['Start a budget for the school year.'],
    's4': ['Follow up with the vendors who have not replied yet.'],
    's5': ['Help me plan the application timeline.'],
  };

  static WorkspaceOverview get overview => WorkspaceOverview(
        workspace: workspace,
        briefing: briefing,
        continueTitle: continueTitle,
        continueSnippet: continueSnippet,
        continueProgress: continueProgress,
        continueProgressLabel: continueProgressLabel,
        tasks: tasks,
        sessions: sessions,
        files: files,
        memories: memories,
        suggestions: suggestions,
      );
}
