import 'package:flutter/material.dart';

/// Lifecycle state of a workspace.
enum WorkspaceStatus {
  active,
  paused,
  atRisk;

  String get label => switch (this) {
        WorkspaceStatus.active => 'Active',
        WorkspaceStatus.paused => 'Paused',
        WorkspaceStatus.atRisk => 'Needs attention',
      };
}

/// A user project / workspace (e.g. GANO, School, Startup).
///
/// Layout-first mock entity. No persistence, no Firestore mapping yet.
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.accent,
    this.cover,
    this.status = WorkspaceStatus.active,
    this.progress = 0,
    this.progressLabel,
    this.pinned = false,
    this.favourite = false,
    this.taskCount = 0,
    this.taskDone = 0,
  });

  final String id;
  final String name;
  final String description;
  final String emoji;

  /// Seed color for the cover gradient.
  final Color accent;

  /// Optional cover gradient override (defaults to a derived [accent] fade).
  final List<Color>? cover;
  final WorkspaceStatus status;
  final double progress;
  final String? progressLabel;
  final bool pinned;
  final bool favourite;
  final int taskCount;
  final int taskDone;
}
