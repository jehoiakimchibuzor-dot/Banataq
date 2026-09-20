import '../../../../core/design_system/design_system.dart';

/// Upload request abstraction — presentation/data boundary.
///
/// Keeps `file_picker`'s `PlatformFile` out of the domain/repository contract.
/// The repository validates and sanitizes before touching Firebase Storage.
class WorkspaceFileUploadRequest {
  const WorkspaceFileUploadRequest({
    required this.localPath,
    required this.fileName,
    this.mimeType,
    required this.sizeBytes,
    required this.type,
  });

  /// Absolute local path (`PlatformFile.path`). Must be non-empty.
  final String localPath;

  /// Original file name (`PlatformFile.name`). Displayed as `WorkspaceFile.name`.
  final String fileName;

  /// MIME type from `PlatformFile` or derived from extension. May be null.
  final String? mimeType;

  /// File size in bytes (`PlatformFile.size`). Must be >0 and ≤50 MB.
  final int sizeBytes;

  /// Presentation category (`AppFileType`) selected by UI.
  final AppFileType type;

  /// Sanitized filename for Storage path segment.
  ///
  /// Removes path traversal (`../`, `/`, `\`) and replaces unsafe chars with `_`.
  /// Keeps original `fileName` in `WorkspaceFile.name` for display.
  String get sanitizedFileName {
    String s = fileName.trim();
    // Strip any directory components
    s = s.replaceAll(RegExp(r'[\\/]'), '_');
    s = s.replaceAll('..', '_');
    // Replace unsafe chars (keep word, dot, dash)
    s = s.replaceAll(RegExp(r'[^\w\-.]'), '_');
    // Collapse whitespace/underscores
    s = s.replaceAll(RegExp(r'_+'), '_');
    // Trim leading dots/underscores
    s = s.replaceFirst(RegExp(r'^[._]+'), '');
    if (s.isEmpty) s = 'file';
    // Limit length to 100 chars, preserve extension if present
    if (s.length > 100) {
      final dot = s.lastIndexOf('.');
      if (dot > 0 && dot < s.length - 1 && s.length - dot <= 10) {
        final ext = s.substring(dot);
        s = '${s.substring(0, 100 - ext.length)}$ext';
      } else {
        s = s.substring(0, 100);
      }
    }
    return s;
  }
}
