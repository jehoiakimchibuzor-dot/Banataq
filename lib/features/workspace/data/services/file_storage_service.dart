import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/app_result.dart';
import '../../domain/models/workspace_file_upload_request.dart';

/// Dedicated Firebase Storage abstraction for workspace files.
///
/// Keeps `firebase_storage` out of presentation and repository orchestration
/// remains in `WorkspaceRepository` (upload → Firestore → rollback).
class FileStorageService {
  static const int kMaxFileSize = 50 * 1024 * 1024; // 50 MB

  final FirebaseStorage? _storage;

  FileStorageService({FirebaseStorage? storage}) : _storage = storage ?? _safeStorage();

  static FirebaseStorage? _safeStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a workspace file to
  /// `users/{uid}/workspaces/{wid}/files/{fid}/{sanitizedFileName}`.
  ///
  /// Returns the storage path (`ref.fullPath`) on success.
  Future<AppResult<String>> uploadWorkspaceFile({
    required String uid,
    required String workspaceId,
    required String fileId,
    required WorkspaceFileUploadRequest request,
  }) async {
    // Validation
    if (uid.isEmpty || workspaceId.isEmpty || fileId.isEmpty) {
      return const Failure(ValidationError('Missing uid/workspace/file id'));
    }
    if (request.localPath.trim().isEmpty) {
      return const Failure(ValidationError('File path is empty'));
    }
    final file = File(request.localPath);
    try {
      final exists = await file.exists();
      if (!exists) return const Failure(ValidationError('File not found'));
    } catch (e) {
      return Failure(ValidationError('File not readable: $e'));
    }
    if (request.sizeBytes <= 0) {
      return const Failure(ValidationError('File is empty'));
    }
    if (request.sizeBytes > kMaxFileSize) {
      return const Failure(ValidationError('File exceeds 50 MB limit'));
    }
    if (request.fileName.trim().isEmpty) {
      return const Failure(ValidationError('File name is empty'));
    }

    final sanitized = request.sanitizedFileName;
    final String storagePath = 'users/$uid/workspaces/$workspaceId/files/$fileId/$sanitized';
    final FirebaseStorage? storage = _storage;
    if (storage == null) {
      return const Failure(ServerError(details: 'Firebase Storage not initialized'));
    }
    final Reference ref = storage.ref().child(storagePath);
    try {
      final SettableMetadata? metadata = request.mimeType != null && request.mimeType!.trim().isNotEmpty
          ? SettableMetadata(contentType: request.mimeType)
          : null;
      if (metadata != null) {
        await ref.putFile(file, metadata);
      } else {
        await ref.putFile(file);
      }
      return Success(ref.fullPath);
    } on FirebaseException catch (e) {
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        return Failure(PermissionDeniedError(e.message ?? e.code));
      }
      if (e.code == 'canceled' || e.code == 'network-request-failed') {
        return Failure(NetworkError(e.message));
      }
      return Failure(ServerError(details: 'Storage upload failed: ${e.message ?? e.code}'));
    } catch (e) {
      return Failure(ServerError(details: 'Storage upload failed: $e'));
    }
  }

  /// Deletes a workspace file from Storage.
  ///
  /// Best-effort: returns success even if file not found.
  Future<AppResult<void>> deleteWorkspaceFile({
    required String storagePath,
  }) async {
    if (storagePath.trim().isEmpty) return const Success(null);
    final FirebaseStorage? storage = _storage;
    if (storage == null) return const Success(null); // no-op in tests without Firebase
    try {
      final Reference ref = storage.ref().child(storagePath);
      await ref.delete();
      return const Success(null);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return const Success(null); // idempotent
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        return Failure(PermissionDeniedError(e.message ?? e.code));
      }
      return Failure(ServerError(details: 'Storage delete failed: ${e.message ?? e.code}'));
    } catch (e) {
      return Failure(ServerError(details: 'Storage delete failed: $e'));
    }
  }

  /// Returns a short-lived download URL for a storage path.
  Future<AppResult<String>> getDownloadUrl(String storagePath) async {
    if (storagePath.trim().isEmpty) {
      return const Failure(ValidationError('Missing storage path'));
    }
    final FirebaseStorage? storage = _storage;
    if (storage == null) {
      return const Failure(ServerError(details: 'Firebase Storage not initialized'));
    }
    try {
      final Reference ref = storage.ref().child(storagePath);
      final String url = await ref.getDownloadURL();
      return Success(url);
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return Failure(NotFoundError(e.message ?? 'File not found'));
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        return Failure(PermissionDeniedError(e.message ?? e.code));
      }
      return Failure(ServerError(details: 'Failed to get download URL: ${e.message ?? e.code}'));
    } catch (e) {
      return Failure(ServerError(details: 'Failed to get download URL: $e'));
    }
  }
}
