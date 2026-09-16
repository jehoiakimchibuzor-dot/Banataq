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
    this.createdAt,
    this.updatedAt,
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Workspace copyWith({
    String? id,
    String? name,
    String? description,
    String? emoji,
    Color? accent,
    List<Color>? cover,
    WorkspaceStatus? status,
    double? progress,
    String? progressLabel,
    bool? pinned,
    bool? favourite,
    int? taskCount,
    int? taskDone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      accent: accent ?? this.accent,
      cover: cover ?? this.cover,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      progressLabel: progressLabel ?? this.progressLabel,
      pinned: pinned ?? this.pinned,
      favourite: favourite ?? this.favourite,
      taskCount: taskCount ?? this.taskCount,
      taskDone: taskDone ?? this.taskDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'emoji': emoji,
        'accent': accent.toARGB32(),
        'cover': cover?.map((c) => c.toARGB32()).toList(),
        'status': status.name,
        'progress': progress,
        'progressLabel': progressLabel,
        'pinned': pinned,
        'favourite': favourite,
        'taskCount': taskCount,
        'taskDone': taskDone,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '',
      accent: json['accent'] is int
          ? Color(json['accent'] as int)
          : const Color(0xFFD4AF5A),
      cover: (json['cover'] as List?)?.map((e) => Color(e as int)).toList(),
      status: WorkspaceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => WorkspaceStatus.active,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      progressLabel: json['progressLabel'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      favourite: json['favourite'] as bool? ?? false,
      taskCount: json['taskCount'] as int? ?? 0,
      taskDone: json['taskDone'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}
