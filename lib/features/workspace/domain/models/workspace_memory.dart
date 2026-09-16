/// A fact Banataq remembers about a workspace.
class WorkspaceMemory {
  const WorkspaceMemory({
    required this.id,
    required this.title,
    required this.content,
    this.category = MemoryCategory.context,
    this.source,
    this.confidence = MemoryConfidence.confirmed,
    this.pinned = false,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final MemoryCategory category;

  /// Where the memory came from ("From session · Aug 1").
  final String? source;
  final MemoryConfidence confidence;
  final bool pinned;
  final DateTime? updatedAt;

  WorkspaceMemory copyWith({
    String? title,
    String? content,
    MemoryCategory? category,
    String? source,
    MemoryConfidence? confidence,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return WorkspaceMemory(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      pinned: pinned ?? this.pinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category.name,
        'source': source,
        'confidence': confidence.name,
        'pinned': pinned,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory WorkspaceMemory.fromJson(Map<String, dynamic> json) {
    return WorkspaceMemory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: MemoryCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MemoryCategory.context,
      ),
      source: json['source'] as String?,
      confidence: MemoryConfidence.values.firstWhere(
        (e) => e.name == json['confidence'],
        orElse: () => MemoryConfidence.confirmed,
      ),
      pinned: json['pinned'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}

/// Memory categories used for filtering.
enum MemoryCategory { preferences, contacts, goals, decisions, context, rules }

extension MemoryCategoryX on MemoryCategory {
  String get label => switch (this) {
        MemoryCategory.preferences => 'Preferences',
        MemoryCategory.contacts => 'Contacts',
        MemoryCategory.goals => 'Goals',
        MemoryCategory.decisions => 'Decisions',
        MemoryCategory.context => 'Context',
        MemoryCategory.rules => 'Rules',
      };

  String get hint => switch (this) {
        MemoryCategory.preferences => 'How you like things done',
        MemoryCategory.contacts => 'People, roles and contacts',
        MemoryCategory.goals => 'Targets you are working towards',
        MemoryCategory.decisions => 'Decisions made and why',
        MemoryCategory.context => 'Background about this workspace',
        MemoryCategory.rules => 'Things that always apply',
      };
}

/// How strongly a fact is established.
enum MemoryConfidence { observed, recurring, confirmed }

extension MemoryConfidenceX on MemoryConfidence {
  String get label => switch (this) {
        MemoryConfidence.observed => 'Observed once',
        MemoryConfidence.recurring => 'Recurring',
        MemoryConfidence.confirmed => 'Confirmed',
      };
}
