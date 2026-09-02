import 'package:flutter/material.dart';
import '../core/design_system/design_system.dart';

/// Home Dashboard models.
///
/// These are layout-first mock models that mirror the design-system card
/// inputs 1:1, so the dashboard can be perfected before any business logic
/// lands. Real entities will replace them in the next increment.
class HomeDashboardData {
  const HomeDashboardData({
    required this.displayName,
    required this.statusLine,
    this.continueItem,
    required this.quickActions,
    required this.insights,
    required this.stats,
    required this.workspaces,
    required this.recentFiles,
    required this.memories,
    required this.suggestions,
    required this.promptSuggestions,
  });

  final String displayName;
  final String statusLine;
  final HomeContinueItem? continueItem;
  final List<HomeQuickAction> quickActions;
  final List<HomeInsight> insights;
  final List<HomeStat> stats;
  final List<HomeWorkspace> workspaces;
  final List<HomeRecentFile> recentFiles;
  final List<HomeMemory> memories;
  final List<HomeSuggestion> suggestions;
  final List<String> promptSuggestions;
}

/// The single "resume-first" hero item. Maps to [ContinueCard].
class HomeContinueItem {
  const HomeContinueItem({
    required this.title,
    this.snippet,
    this.progress,
    this.progressLabel,
    this.contextLabel,
    this.emoji,
    this.icon,
    this.ctaLabel = 'Continue',
  });

  final String title;
  final String? snippet;
  final double? progress;
  final String? progressLabel;
  final String? contextLabel;
  final String? emoji;
  final IconData? icon;
  final String ctaLabel;
}

enum HomeQuickActionKind { askAi, newWorkspace, upload, voice }

class HomeQuickAction {
  const HomeQuickAction({
    required this.kind,
    required this.label,
    required this.icon,
    this.subtitle,
    this.accent,
  });

  final HomeQuickActionKind kind;
  final String label;
  final IconData icon;
  final String? subtitle;
  final Color? accent;
}

/// A passive AI insight. Maps to [InsightCard].
class HomeInsight {
  const HomeInsight({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.actionLabel,
    this.tone = StatusTone.info,
  });

  final String id;
  final String title;
  final String? description;
  final IconData? icon;
  final String? actionLabel;
  final StatusTone tone;
}

/// A KPI tile. Maps to [StatisticsCard].
class HomeStat {
  const HomeStat({
    required this.value,
    required this.label,
    this.delta,
    this.deltaDirection = TrendDirection.up,
    this.icon,
    this.tone = StatusTone.info,
  });

  final String value;
  final String label;
  final String? delta;
  final TrendDirection deltaDirection;
  final IconData? icon;
  final StatusTone tone;
}

/// A project / workspace. Maps to [WorkspaceCard].
class HomeWorkspace {
  const HomeWorkspace({
    required this.id,
    required this.title,
    this.subtitle,
    this.emoji,
    this.icon,
    this.progress,
    this.progressLabel,
    this.summary,
    this.lastActivity,
    this.pinned = false,
    this.selected = false,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? emoji;
  final IconData? icon;
  final double? progress;
  final String? progressLabel;
  final String? summary;
  final String? lastActivity;
  final bool pinned;
  final bool selected;
}

/// A recent file artifact. Maps to [FileCard].
class HomeRecentFile {
  const HomeRecentFile({
    required this.id,
    required this.name,
    required this.type,
    this.meta,
    this.summarized = false,
  });

  final String id;
  final String name;
  final AppFileType type;
  final String? meta;
  final bool summarized;
}

/// A project memory fact. Maps to [MemoryCard].
class HomeMemory {
  const HomeMemory({
    required this.id,
    required this.title,
    required this.content,
    this.source,
  });

  final String id;
  final String title;
  final String content;
  final String? source;
}

/// A proactive suggestion. Maps to [SuggestionCard].
class HomeSuggestion {
  const HomeSuggestion({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.applyLabel = 'Do this',
  });

  final String id;
  final String title;
  final String? description;
  final IconData? icon;
  final String applyLabel;
}
