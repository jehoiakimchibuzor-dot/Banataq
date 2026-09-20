import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/design_system/design_system.dart';

/// A file artifact inside a workspace. Reuses the design-system [AppFileType]
/// so the [FileCard] maps directly.
///
/// Extended for real file lifecycle (PR #3F): [mimeType]/[sizeBytes]/[storagePath]
/// are the Storage-backed fields. [storagePath] is the canonical Firebase
/// Storage location (`users/{uid}/workspaces/{wid}/files/{fid}/<sanitized>`),
/// not a long-lived download URL.
class WorkspaceFile {
  const WorkspaceFile({
    required this.id,
    required this.name,
    required this.type,
    this.mimeType,
    this.sizeBytes = 0,
    this.storagePath,
    this.meta,
    this.summarized = false,
    this.summary,
    this.createdAt,
    this.updatedAt,
    this.favourite = false,
    this.pinned = false,
    this.tags = const [],
  });

  final String id;
  final String name;
  final AppFileType type;

  /// MIME type derived from the picked file (e.g. `application/pdf`).
  final String? mimeType;

  /// File size in bytes (0 for legacy placeholder docs).
  final int sizeBytes;

  /// Canonical Firebase Storage path
  /// `users/{uid}/workspaces/{wid}/files/{fid}/<sanitizedFilename>`.
  /// `null` for legacy placeholder docs without a real upload.
  final String? storagePath;

  /// Display metadata line (e.g. "24 KB · Updated 2h ago").
  final String? meta;
  final bool summarized;

  /// AI-authored summary of the file's contents (present when [summarized]).
  final String? summary;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool favourite;
  final bool pinned;
  final List<String> tags;

  WorkspaceFile copyWith({
    String? name,
    AppFileType? type,
    String? mimeType,
    int? sizeBytes,
    String? storagePath,
    String? meta,
    bool? summarized,
    String? summary,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? favourite,
    bool? pinned,
    List<String>? tags,
  }) {
    return WorkspaceFile(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      storagePath: storagePath ?? this.storagePath,
      meta: meta ?? this.meta,
      summarized: summarized ?? this.summarized,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favourite: favourite ?? this.favourite,
      pinned: pinned ?? this.pinned,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'storagePath': storagePath,
        'meta': meta,
        'summarized': summarized,
        'summary': summary,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'favourite': favourite,
        'pinned': pinned,
        'tags': tags,
      };

  factory WorkspaceFile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      if (raw is String) return DateTime.tryParse(raw);
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return null;
    }

    return WorkspaceFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: AppFileType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AppFileType.unknown,
      ),
      mimeType: json['mimeType'] as String?,
      sizeBytes: () {
        final v = json['sizeBytes'];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      }(),
      storagePath: json['storagePath'] as String?,
      meta: json['meta'] as String?,
      summarized: json['summarized'] is bool ? json['summarized'] as bool : false,
      summary: json['summary'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      favourite: json['favourite'] is bool ? json['favourite'] as bool : false,
      pinned: json['pinned'] is bool ? json['pinned'] as bool : false,
      tags: json['tags'] is List ? (json['tags'] as List).map((e) => e.toString()).toList() : const [],
    );
  }
}
