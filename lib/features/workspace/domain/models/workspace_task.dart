/// A checklist line inside a task.
class WorkspaceSubtask {
  const WorkspaceSubtask({
    required this.id,
    required this.title,
    required this.done,
  });

  final String id;
  final String title;
  final bool done;

  WorkspaceSubtask copyWith({bool? done}) {
    return WorkspaceSubtask(id: id, title: title, done: done ?? this.done);
  }
}

/// Where a task came from.
enum TaskSource { manual, ai }

extension TaskSourceX on TaskSource {
  String get label => switch (this) {
        TaskSource.manual => 'Manual',
        TaskSource.ai => 'AI suggested',
      };
}

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
      };
}

/// Scheduling bucket for open tasks, derived from [WorkspaceTask.dueDate].
enum TaskDueGroup { overdue, today, upcoming, none }

extension TaskDueGroupX on TaskDueGroup {
  String get label => switch (this) {
        TaskDueGroup.overdue => 'Overdue',
        TaskDueGroup.today => 'Today',
        TaskDueGroup.upcoming => 'Upcoming',
        TaskDueGroup.none => 'No date',
      };
}

/// A single task inside a workspace.
class WorkspaceTask {
  const WorkspaceTask({
    required this.id,
    required this.title,
    required this.done,
    this.priority = TaskPriority.medium,
    this.dueLabel,
    this.dueDate,
    this.contextLabel,
    this.createdAt,
    this.source = TaskSource.manual,
    this.subtasks = const [],
    this.linkedSessionIds = const [],
    this.linkedFileIds = const [],
    this.archived = false,
  });

  final String id;
  final String title;
  final bool done;
  final TaskPriority priority;
  final String? dueLabel;
  final DateTime? dueDate;
  final String? contextLabel;
  final DateTime? createdAt;
  final TaskSource source;
  final List<WorkspaceSubtask> subtasks;
  final List<String> linkedSessionIds;
  final List<String> linkedFileIds;
  final bool archived;

  int get doneSubtasks => subtasks.where((s) => s.done).length;

  bool get hasSubtasks => subtasks.isNotEmpty;

  bool get isOverdue => dueDate != null && !done && _beforeToday(dueDate!);

  /// The display label for the due date, preferring an explicit override.
  String get effectiveDueLabel {
    if (dueLabel != null) return dueLabel!;
    final due = dueDate;
    if (due == null) return 'No date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${day.day}/${day.month}';
    if (diff < 7) {
      return switch (day.weekday) {
        1 => 'Mon',
        2 => 'Tue',
        3 => 'Wed',
        4 => 'Thu',
        5 => 'Fri',
        6 => 'Sat',
        _ => 'Sun',
      };
    }
    return '${day.day}/${day.month}';
  }

  WorkspaceTask copyWith({
    String? title,
    bool? done,
    TaskPriority? priority,
    String? dueLabel,
    DateTime? dueDate,
    String? contextLabel,
    TaskSource? source,
    List<WorkspaceSubtask>? subtasks,
    bool? archived,
  }) {
    return WorkspaceTask(
      id: id,
      title: title ?? this.title,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      dueLabel: dueLabel ?? this.dueLabel,
      dueDate: dueDate ?? this.dueDate,
      contextLabel: contextLabel ?? this.contextLabel,
      createdAt: createdAt,
      source: source ?? this.source,
      subtasks: subtasks ?? this.subtasks,
      linkedSessionIds: linkedSessionIds,
      linkedFileIds: linkedFileIds,
      archived: archived ?? this.archived,
    );
  }

  static bool _beforeToday(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    return day.isBefore(today);
  }
}

extension WorkspaceTaskDueX on WorkspaceTask {
  TaskDueGroup get dueGroup {
    if (done) return TaskDueGroup.none;
    final due = dueDate;
    if (due == null) return TaskDueGroup.none;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    if (diff < 0) return TaskDueGroup.overdue;
    if (diff == 0) return TaskDueGroup.today;
    return TaskDueGroup.upcoming;
  }
}
