import '../../../../core/design_system/design_system.dart';

/// A file artifact inside a workspace. Reuses the design-system [AppFileType]
/// so the [FileCard] maps directly.
class WorkspaceFile {
  const WorkspaceFile({
    required this.id,
    required this.name,
    required this.type,
    this.meta,
    this.summarized = false,
    this.summary,
    this.createdAt,
    this.favourite = false,
    this.pinned = false,
    this.tags = const [],
  });

  final String id;
  final String name;
  final AppFileType type;

  /// Display metadata line (e.g. "24 KB · Updated 2h ago").
  final String? meta;
  final bool summarized;

  /// AI-authored summary of the file's contents (present when [summarized]).
  final String? summary;
  final DateTime? createdAt;
  final bool favourite;
  final bool pinned;
  final List<String> tags;

  WorkspaceFile copyWith({
    String? name,
    AppFileType? type,
    String? meta,
    bool? summarized,
    String? summary,
    DateTime? createdAt,
    bool? favourite,
    bool? pinned,
    List<String>? tags,
  }) {
    return WorkspaceFile(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      meta: meta ?? this.meta,
      summarized: summarized ?? this.summarized,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      favourite: favourite ?? this.favourite,
      pinned: pinned ?? this.pinned,
      tags: tags ?? this.tags,
    );
  }
}
