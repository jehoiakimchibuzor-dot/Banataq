import 'package:flutter/material.dart';
import '../../core/design_system/design_system.dart';
import 'home_dashboard_models.dart';

/// Fake, realistic Home Dashboard data used only by the layout increment.
///
/// This is the single source of fake data for the Home screen. It will be
/// deleted when real repositories land.
abstract final class MockHomeDashboardData {
  static HomeDashboardData get data => HomeDashboardData(
        displayName: 'Ibrahim',
        statusLine: '3 tasks due this week · 14 sessions',
        continueItem: const HomeContinueItem(
          title: 'GANO supplier comparison',
          snippet:
              'You were comparing three suppliers for the packaging order. '
              'Draft the decision table and send it to Alhaji Musa.',
          contextLabel: 'Continue from GANO',
          progress: 0.5,
          progressLabel: '3 of 6 tasks',
          emoji: '🚀',
        ),
        quickActions: const [
          HomeQuickAction(
            kind: HomeQuickActionKind.askAi,
            label: 'Ask AI',
            subtitle: 'Anything',
            icon: Icons.auto_awesome_rounded,
            accent: Color(0xFF8B5CF6),
          ),
          HomeQuickAction(
            kind: HomeQuickActionKind.newWorkspace,
            label: 'New workspace',
            subtitle: 'Project',
            icon: Icons.folder_open_rounded,
            accent: Color(0xFFE2C477),
          ),
          HomeQuickAction(
            kind: HomeQuickActionKind.upload,
            label: 'Upload file',
            subtitle: 'PDF, DOCX',
            icon: Icons.upload_file_rounded,
            accent: Color(0xFF10B981),
          ),
          HomeQuickAction(
            kind: HomeQuickActionKind.voice,
            label: 'Voice note',
            subtitle: 'Talk to AI',
            icon: Icons.mic_rounded,
            accent: Color(0xFFF59E0B),
          ),
        ],
        insights: const [
          HomeInsight(
            id: 'insight-1',
            title: 'You work best in the morning',
            description:
                'Most of your focused sessions this week happened before 9 AM.',
            actionLabel: 'See focus stats',
          ),
          HomeInsight(
            id: 'insight-2',
            title: 'GANO deadline is Friday',
            description: 'The supplier decision is due in 3 days.',
            tone: StatusTone.warning,
            actionLabel: 'Plan this week',
          ),
        ],
        stats: const [
          HomeStat(
            value: '14',
            label: 'Sessions',
            delta: '+3 this week',
            deltaDirection: TrendDirection.up,
            icon: Icons.forum_rounded,
          ),
          HomeStat(
            value: '6',
            label: 'Workspaces',
            delta: '+1',
            deltaDirection: TrendDirection.up,
            icon: Icons.folder_rounded,
          ),
          HomeStat(
            value: '12',
            label: 'Files',
            delta: '+2 today',
            deltaDirection: TrendDirection.up,
            icon: Icons.description_rounded,
          ),
          HomeStat(
            value: '87%',
            label: 'Tasks done',
            deltaDirection: TrendDirection.up,
            icon: Icons.check_circle_rounded,
            tone: StatusTone.success,
          ),
        ],
        workspaces: const [
          HomeWorkspace(
            id: 'ws-1',
            title: 'GANO',
            subtitle: 'School & career',
            emoji: '🚀',
            progress: 0.5,
            progressLabel: '3 of 6',
            summary: 'Comparing suppliers and drafting the price list.',
            lastActivity: 'Edited 2h ago',
            pinned: true,
            selected: true,
          ),
          HomeWorkspace(
            id: 'ws-2',
            title: 'Boutique Launch',
            subtitle: 'Business',
            emoji: '🛍️',
            progress: 0.75,
            progressLabel: '6 of 8',
            summary: 'Choosing a name and checking trademark availability.',
            lastActivity: 'Edited yesterday',
          ),
          HomeWorkspace(
            id: 'ws-3',
            title: 'Final Year Project',
            subtitle: 'School',
            emoji: '📚',
            progress: 0.35,
            progressLabel: '2 of 6',
            summary: 'Literature review — electric vehicles in Lagos.',
            lastActivity: 'Edited 3 days ago',
          ),
          HomeWorkspace(
            id: 'ws-4',
            title: 'Farm Record Book',
            subtitle: 'Business',
            emoji: '🌾',
            progress: 0.1,
            progressLabel: '1 of 10',
            summary: 'Tracking feed costs and yields per pen.',
            lastActivity: 'Edited last week',
          ),
        ],
        recentFiles: const [
          HomeRecentFile(
            id: 'file-1',
            name: 'suppliers_quote.xlsx',
            type: AppFileType.sheet,
            meta: '24 KB · Updated 2h ago',
            summarized: true,
          ),
          HomeRecentFile(
            id: 'file-2',
            name: 'gana_pitch_deck.pdf',
            type: AppFileType.pdf,
            meta: '1.2 MB · Yesterday',
            summarized: true,
          ),
          HomeRecentFile(
            id: 'file-3',
            name: 'market_scan.png',
            type: AppFileType.image,
            meta: '380 KB · Yesterday',
          ),
          HomeRecentFile(
            id: 'file-4',
            name: 'briefing.docx',
            type: AppFileType.document,
            meta: '86 KB · Mon',
          ),
        ],
        memories: const [
          HomeMemory(
            id: 'mem-1',
            title: 'Alhaji Musa approves orders',
            content: 'GANO packaging orders need Alhaji Musa’s sign-off.',
            source: 'From Aug 1 session',
          ),
          HomeMemory(
            id: 'mem-2',
            title: 'Preferred currency',
            content: 'Always present supplier quotes in Naira.',
            source: 'From workspace',
          ),
          HomeMemory(
            id: 'mem-3',
            title: 'Carrier preference',
            content: 'Uses GIG Logistics for Abuja deliveries.',
            source: 'From GANO',
          ),
        ],
        suggestions: const [
          HomeSuggestion(
            id: 'sug-1',
            title: 'Draft the supplier decision table',
            description:
                'I can turn your three quotes into a comparison table you can send.',
            icon: Icons.table_chart_rounded,
          ),
          HomeSuggestion(
            id: 'sug-2',
            title: 'Summarize this week',
            description:
                'Here’s what happened across your workspaces this week.',
            icon: Icons.auto_awesome_rounded,
          ),
        ],
        promptSuggestions: const [
          'Explain a concept',
          'Draft a message',
          'Summarize a note',
          'Plan my week',
        ],
      );
}
