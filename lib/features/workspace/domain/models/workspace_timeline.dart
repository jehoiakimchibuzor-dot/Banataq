import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Kind of activity shown on the Timeline tab.
enum TimelineEventType { session, task, file, memory, suggestion, milestone }

extension TimelineEventTypeX on TimelineEventType {
  String get label => switch (this) {
        TimelineEventType.session => 'Session',
        TimelineEventType.task => 'Task',
        TimelineEventType.file => 'File',
        TimelineEventType.memory => 'Memory',
        TimelineEventType.suggestion => 'Suggestion',
        TimelineEventType.milestone => 'Milestone',
      };

  IconData get icon => switch (this) {
        TimelineEventType.session => Icons.forum_outlined,
        TimelineEventType.task => Icons.checklist_rounded,
        TimelineEventType.file => Icons.folder_outlined,
        TimelineEventType.memory => Icons.lightbulb_outline_rounded,
        TimelineEventType.suggestion => Icons.auto_awesome_rounded,
        TimelineEventType.milestone => Icons.flag_outlined,
      };
}

/// One activity entry on the workspace timeline.
class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.occurredAt,
    this.description,
    this.refId,
  });

  final String id;
  final TimelineEventType type;
  final String title;
  final String? description;
  final DateTime occurredAt;

  /// Id of the underlying entity (session, task, file, memory), if any.
  final String? refId;

  TimelineEvent copyWith({
    String? id,
    TimelineEventType? type,
    String? title,
    String? description,
    DateTime? occurredAt,
    String? refId,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      occurredAt: occurredAt ?? this.occurredAt,
      refId: refId ?? this.refId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'description': description,
        'refId': refId,
        'occurredAt': Timestamp.fromDate(occurredAt),
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    // occurredAt compatibility: Timestamp | DateTime | String | int | null
    DateTime occurredAt;
    final dynamic rawAt = json['occurredAt'];
    if (rawAt == null) {
      // No timestamp stored — use now as fallback (serverTimestamp pending)
      occurredAt = DateTime.now();
    } else if (rawAt is Timestamp) {
      occurredAt = rawAt.toDate();
    } else if (rawAt is DateTime) {
      occurredAt = rawAt;
    } else if (rawAt is String) {
      occurredAt = DateTime.tryParse(rawAt) ?? DateTime.now();
    } else if (rawAt is int) {
      occurredAt = DateTime.fromMillisecondsSinceEpoch(rawAt);
    } else {
      occurredAt = DateTime.now();
    }

    final String rawType = json['type'] as String? ?? 'session';
    final TimelineEventType type = TimelineEventType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => TimelineEventType.session,
    );

    return TimelineEvent(
      id: json['id'] as String? ?? '',
      type: type,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      occurredAt: occurredAt,
      refId: json['refId'] as String?,
    );
  }
}
