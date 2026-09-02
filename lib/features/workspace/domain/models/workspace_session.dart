/// Lifecycle status of a working session.
enum SessionStatus { inProgress, idle, completed, archived }

extension SessionStatusX on SessionStatus {
  String get label => switch (this) {
        SessionStatus.inProgress => 'In progress',
        SessionStatus.idle => 'Paused',
        SessionStatus.completed => 'Completed',
        SessionStatus.archived => 'Archived',
      };

  bool get isArchived => this == SessionStatus.archived;
}

/// Grouping of sessions by recency.
enum SessionGroup { today, yesterday, thisWeek, earlier }

extension SessionGroupX on SessionGroup {
  String get label => switch (this) {
        SessionGroup.today => 'Today',
        SessionGroup.yesterday => 'Yesterday',
        SessionGroup.thisWeek => 'This week',
        SessionGroup.earlier => 'Earlier',
      };
}

/// A working session inside a workspace (the successor of "conversation").
class WorkspaceSession {
  const WorkspaceSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.summary,
    this.purpose,
    this.preview,
    this.status = SessionStatus.completed,
    this.pinned = false,
    this.messageCount = 0,
    this.durationLabel,
    this.linkedFileIds = const [],
    this.linkedTaskIds = const [],
    this.createdAt,
  });

  final String id;
  final String title;

  /// Short AI-written summary shown on cards and the Overview tab.
  final String? summary;

  /// The stated goal for the session ("Compare the three supplier quotes").
  final String? purpose;

  /// One-line preview of what happened in the session.
  final String? preview;
  final DateTime updatedAt;
  final DateTime? createdAt;
  final SessionStatus status;
  final bool pinned;
  final int messageCount;
  final String? durationLabel;
  final List<String> linkedFileIds;
  final List<String> linkedTaskIds;

  bool get active => status == SessionStatus.inProgress;

  bool get archived => status == SessionStatus.archived;

  WorkspaceSession copyWith({
    String? title,
    String? summary,
    String? purpose,
    String? preview,
    SessionStatus? status,
    bool? pinned,
    int? messageCount,
    String? durationLabel,
    DateTime? updatedAt,
    List<String>? linkedFileIds,
    List<String>? linkedTaskIds,
  }) {
    return WorkspaceSession(
      id: id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      summary: summary ?? this.summary,
      purpose: purpose ?? this.purpose,
      preview: preview ?? this.preview,
      status: status ?? this.status,
      pinned: pinned ?? this.pinned,
      messageCount: messageCount ?? this.messageCount,
      durationLabel: durationLabel ?? this.durationLabel,
      linkedFileIds: linkedFileIds ?? this.linkedFileIds,
      linkedTaskIds: linkedTaskIds ?? this.linkedTaskIds,
      createdAt: createdAt,
    );
  }
}
