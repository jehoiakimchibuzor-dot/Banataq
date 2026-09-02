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
}
