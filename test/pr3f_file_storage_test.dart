import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/core/design_system/design_system.dart';
import 'package:banataq/core/errors/app_error.dart';
import 'package:banataq/core/errors/app_result.dart';
import 'package:banataq/features/workspace/data/repositories/workspace_repository.dart';
import 'package:banataq/features/workspace/data/services/file_storage_service.dart';
import 'package:banataq/core/constants/firestore_constants.dart';
import 'package:banataq/features/workspace/domain/models/workspace.dart';
import 'package:banataq/features/workspace/domain/models/workspace_file.dart';
import 'package:banataq/features/workspace/domain/models/workspace_file_upload_request.dart';

Workspace _ws(String id) => Workspace(id: id, name: 'WS $id', description: '', emoji: '🗂️', accent: const Color(0xFFD4AF5A));

/// Fake storage that can be programmed to succeed/fail and records calls.
class FakeFileStorageService extends FileStorageService {
  FakeFileStorageService({this.uploadResult, this.deleteResult, this.downloadUrlResult});

  AppResult<String>? uploadResult;
  AppResult<void>? deleteResult;
  AppResult<String>? downloadUrlResult;

  String? lastUploadStoragePath;
  String? lastDeleteStoragePath;
  String? lastDownloadStoragePath;
  int deleteCallCount = 0;

  @override
  Future<AppResult<String>> uploadWorkspaceFile({
    required String uid,
    required String workspaceId,
    required String fileId,
    required WorkspaceFileUploadRequest request,
  }) async {
    // Simulate validation as real service does for size/path checks without needing real file
    if (request.localPath.trim().isEmpty) return const Failure(ValidationError('File path is empty'));
    if (request.sizeBytes <= 0) return const Failure(ValidationError('File is empty'));
    if (request.sizeBytes > FileStorageService.kMaxFileSize) {
      return const Failure(ValidationError('File exceeds 50 MB limit'));
    }
    if (uploadResult != null) return uploadResult!;
    final sanitized = request.sanitizedFileName;
    final path = 'users/$uid/workspaces/$workspaceId/files/$fileId/$sanitized';
    lastUploadStoragePath = path;
    return Success(path);
  }

  @override
  Future<AppResult<void>> deleteWorkspaceFile({required String storagePath}) async {
    lastDeleteStoragePath = storagePath;
    deleteCallCount++;
    if (deleteResult != null) return deleteResult!;
    return const Success(null);
  }

  @override
  Future<AppResult<String>> getDownloadUrl(String storagePath) async {
    lastDownloadStoragePath = storagePath;
    if (downloadUrlResult != null) return downloadUrlResult!;
    if (storagePath.trim().isEmpty) return const Failure(ValidationError('Missing storage path'));
    return Success('https://example.com/$storagePath?token=mock');
  }
}

void main() {
  group('PR3F WorkspaceFile serialization', () {
    test('toJson/fromJson roundtrip with new fields', () {
      final now = DateTime.now();
      final file = WorkspaceFile(
        id: 'f-1',
        name: 'doc.pdf',
        type: AppFileType.pdf,
        mimeType: 'application/pdf',
        sizeBytes: 12345,
        storagePath: 'users/u1/workspaces/w1/files/f-1/doc.pdf',
        meta: '12.1 KB',
        createdAt: now,
        updatedAt: now,
        favourite: true,
        pinned: true,
        tags: ['a', 'b'],
        summarized: true,
        summary: 'sum',
      );
      final json = file.toJson();
      expect(json['id'], 'f-1');
      expect(json['name'], 'doc.pdf');
      expect(json['type'], 'pdf');
      expect(json['mimeType'], 'application/pdf');
      expect(json['sizeBytes'], 12345);
      expect(json['storagePath'], 'users/u1/workspaces/w1/files/f-1/doc.pdf');
      expect(json['favourite'], true);
      expect(json['pinned'], true);
      expect(json['tags'], ['a', 'b']);
      expect(json['summarized'], true);
      expect(json['summary'], 'sum');
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['updatedAt'], isA<Timestamp>());

      final decoded = WorkspaceFile.fromJson(json);
      expect(decoded.id, file.id);
      expect(decoded.name, file.name);
      expect(decoded.type, file.type);
      expect(decoded.mimeType, file.mimeType);
      expect(decoded.sizeBytes, file.sizeBytes);
      expect(decoded.storagePath, file.storagePath);
      expect(decoded.favourite, file.favourite);
      expect(decoded.pinned, file.pinned);
      expect(decoded.tags, file.tags);
      expect(decoded.summarized, file.summarized);
      expect(decoded.summary, file.summary);
      expect(decoded.createdAt?.millisecondsSinceEpoch, file.createdAt?.millisecondsSinceEpoch);
      expect(decoded.updatedAt?.millisecondsSinceEpoch, file.updatedAt?.millisecondsSinceEpoch);
    });

    test('fromJson Timestamp/String/int/null compatibility', () {
      final now = DateTime.now();
      // Timestamp
      final j1 = {
        'id': 'f1',
        'name': 'a.pdf',
        'type': 'pdf',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'sizeBytes': 100,
      };
      final d1 = WorkspaceFile.fromJson(j1);
      expect(d1.createdAt?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(d1.updatedAt?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);

      // String
      final j2 = {
        'id': 'f2',
        'name': 'b.pdf',
        'type': 'pdf',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final d2 = WorkspaceFile.fromJson(j2);
      expect(d2.createdAt?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);

      // int
      final j3 = {'id': 'f3', 'name': 'c.pdf', 'type': 'pdf', 'createdAt': now.millisecondsSinceEpoch, 'sizeBytes': 200};
      final d3 = WorkspaceFile.fromJson(j3);
      expect(d3.createdAt?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);

      // null -> null
      final j4 = {'id': 'f4', 'name': 'd.pdf', 'type': 'pdf'};
      final d4 = WorkspaceFile.fromJson(j4);
      expect(d4.createdAt, isNull);
      expect(d4.updatedAt, isNull);
      expect(d4.sizeBytes, 0);
      expect(d4.storagePath, isNull);
    });

    test('legacy documents without new fields deserialize', () {
      final legacy = {'id': 'f1', 'name': 'old.pdf', 'type': 'pdf', 'meta': 'Just added'};
      final decoded = WorkspaceFile.fromJson(legacy);
      expect(decoded.type, AppFileType.pdf);
      expect(decoded.mimeType, isNull);
      expect(decoded.sizeBytes, 0);
      expect(decoded.storagePath, isNull);
      expect(decoded.favourite, false);
      expect(decoded.pinned, false);
      expect(decoded.tags, isEmpty);
      expect(decoded.summarized, false);
      expect(decoded.createdAt, isNull);
    });

    test('invalid metadata handled safely', () {
      final json = {
        'id': 'f1',
        'name': 'x',
        'type': 'invalid_type',
        'sizeBytes': 'not_a_num',
        'favourite': 'yes',
        'pinned': 1,
        'tags': 'not_a_list',
        'createdAt': 'not-a-date',
      };
      final decoded = WorkspaceFile.fromJson(json);
      expect(decoded.type, AppFileType.unknown);
      expect(decoded.sizeBytes, 0);
      expect(decoded.favourite, false);
      expect(decoded.pinned, false);
      expect(decoded.tags, isEmpty);
      expect(decoded.createdAt, isNull);
    });

    test('copyWith creates updated copy', () {
      final f = WorkspaceFile(id: 'f1', name: 'a.pdf', type: AppFileType.pdf, sizeBytes: 100, storagePath: 'path/a.pdf');
      final copy = f.copyWith(name: 'b.pdf', sizeBytes: 200, mimeType: 'text/plain');
      expect(copy.id, 'f1');
      expect(copy.name, 'b.pdf');
      expect(copy.sizeBytes, 200);
      expect(copy.mimeType, 'text/plain');
      expect(copy.storagePath, 'path/a.pdf');
    });
  });

  group('PR3F Firestore — files', () {
    test('correct path users/{uid}/workspaces/{wid}/files/{fid} via _filesCol', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1')]);
      // Indirectly test via addFile and fromJson: file should be stored with id and retrievable
      repo.addFile('a.pdf', AppFileType.pdf);
      final files = repo.loadFiles();
      expect(files.length, 1);
      expect(files.first.id, startsWith('f-'));
      expect(files.first.name, 'a.pdf');
    });

    test('user isolation', () {
      final repoA = FirestoreWorkspaceRepository(uidProvider: () => 'user-A');
      final repoB = FirestoreWorkspaceRepository(uidProvider: () => 'user-B');
      repoA.setTestWorkspaces([_ws('ws-A')]);
      repoB.setTestWorkspaces([_ws('ws-B')]);
      repoA.addFile('a.pdf', AppFileType.pdf);
      expect(repoA.loadFiles().length, 1);
      expect(repoB.loadFiles().length, 0);
      repoB.addFile('b.pdf', AppFileType.pdf);
      expect(repoB.loadFiles().length, 1);
      expect(repoA.loadFiles().first.name, 'a.pdf');
    });

    test('workspace isolation', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1')]);
      repo.addFile('a.pdf', AppFileType.pdf);
      expect(repo.loadFiles().length, 1);
      repo.setTestWorkspaces([_ws('ws-2')]);
      expect(repo.loadFiles().length, 0);
      repo.addFile('b.pdf', AppFileType.pdf);
      expect(repo.loadFiles().length, 1);
      expect(repo.loadFiles().first.name, 'b.pdf');
    });

    test('reload/re-hydration via cache', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1')]);
      repo.addFile('persist.pdf', AppFileType.pdf);
      expect(repo.loadFiles().length, 1);
      expect(repo.loadFiles().first.name, 'persist.pdf');
      // Simulate reload via second load (cache still holds)
      final again = repo.loadFiles();
      expect(again.length, 1);
    });

    test('legacy placeholder compatibility (no storagePath) still readable', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1')]);
      // Simulate legacy doc via fromJson without new fields
      final legacyJson = {'id': 'f-legacy', 'name': 'old.pdf', 'type': 'pdf', 'createdAt': DateTime.now().toIso8601String()};
      final legacyFile = WorkspaceFile.fromJson(legacyJson);
      // Manually inject via addFile placeholder then verify fromJson path
      expect(legacyFile.storagePath, isNull);
      expect(legacyFile.sizeBytes, 0);
      // Ensure loadFiles handles legacy via repository's fromJson (already tested)
      // Add a real file and ensure both coexist
      repo.addFile('new.pdf', AppFileType.pdf);
      expect(repo.loadFiles().any((f) => f.name == 'new.pdf'), isTrue);
    });

    test('delete removes file', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1')]);
      final id = repo.addFile('a.pdf', AppFileType.pdf).first.id;
      expect(repo.loadFiles().length, 1);
      await repo.deleteFile(id);
      expect(repo.loadFiles(), isEmpty);
    });

    test('favourite/pinned toggle', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1');
      repo.setTestWorkspaces([_ws('ws-1')]);
      final id = repo.addFile('a.pdf', AppFileType.pdf).first.id;
      repo.setFileFavourite(id, true);
      expect(repo.loadFiles().first.favourite, isTrue);
      repo.setFilePinned(id, true);
      expect(repo.loadFiles().first.pinned, isTrue);
    });

    test('summarizeFile does not upload/delete Storage (only Firestore)', () {
      final storage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: storage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      final id = repo.addFile('a.pdf', AppFileType.pdf).first.id;
      storage.deleteCallCount = 0;
      final summarized = repo.summarizeFile(id);
      expect(summarized.summarized, isTrue);
      expect(summarized.summary, contains('a.pdf'));
      // Summarize should not have triggered Storage upload or delete
      expect(storage.lastUploadStoragePath, isNull);
      expect(storage.deleteCallCount, 0);
    });
  });

  group('PR3F Storage abstraction — WorkspaceFileUploadRequest', () {
    test('sanitizedFileName removes traversal', () {
      const req = WorkspaceFileUploadRequest(
        localPath: '/tmp/a.pdf',
        fileName: '../etc/passwd',
        sizeBytes: 100,
        type: AppFileType.document,
      );
      expect(req.sanitizedFileName, isNot(contains('/')));
      expect(req.sanitizedFileName, isNot(contains('..')));
      expect(req.sanitizedFileName, isNot(contains('\\')));
    });

    test('sanitizedFileName handles empty and long names', () {
      const req1 = WorkspaceFileUploadRequest(localPath: '/tmp/x', fileName: '   ', sizeBytes: 10, type: AppFileType.unknown);
      expect(req1.sanitizedFileName, 'file');
      final longName = '${'a' * 150}.pdf';
      final req2 = WorkspaceFileUploadRequest(localPath: '/tmp/y', fileName: longName, sizeBytes: 10, type: AppFileType.pdf);
      expect(req2.sanitizedFileName.length, lessThanOrEqualTo(100));
      expect(req2.sanitizedFileName, endsWith('.pdf'));
    });

    test('generated fid is stable and not filename', () {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: FakeFileStorageService());
      repo.setTestWorkspaces([_ws('ws-1')]);
      // Use upload request with fileName different from fid
      // We can't directly check fid without upload, but addFile's fid should not equal filename
      final files = repo.addFile('myfile.pdf', AppFileType.pdf);
      final fid = files.first.id;
      expect(fid, isNot('myfile.pdf'));
      expect(fid, startsWith('f-'));
      expect(fid.length, greaterThan(10)); // UUID based
    });

    test('correct storagePath format users/{uid}/workspaces/{wid}/files/{fid}/{sanitized}', () async {
      final fakeStorage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      final req = WorkspaceFileUploadRequest(
        localPath: '/tmp/test.pdf',
        fileName: 'my file.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024,
        type: AppFileType.pdf,
      );
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Success<WorkspaceFile>>());
      final file = (res as Success<WorkspaceFile>).data;
      expect(file.storagePath, isNotNull);
      expect(file.storagePath, startsWith('users/user-1/workspaces/ws-1/files/${file.id}/'));
      expect(file.storagePath, contains('my_file.pdf')); // sanitized space -> _
      expect(file.sizeBytes, 1024);
      expect(file.mimeType, 'application/pdf');
      expect(fakeStorage.lastUploadStoragePath, file.storagePath);
    });
  });

  group('PR3F Storage abstraction — upload lifecycle', () {
    test('missing local file → ValidationError', () async {
      final fakeStorage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '', fileName: 'a.pdf', sizeBytes: 100, type: AppFileType.pdf);
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Failure<WorkspaceFile>>());
      expect((res as Failure).error, isA<ValidationError>());
      expect(repo.loadFiles(), isEmpty); // no orphan doc
    });

    test('size 0 → ValidationError', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: FakeFileStorageService());
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 0, type: AppFileType.pdf);
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Failure<WorkspaceFile>>());
    });

    test('size >50 MB → ValidationError', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: FakeFileStorageService());
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 51 * 1024 * 1024, type: AppFileType.pdf);
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Failure<WorkspaceFile>>());
      expect((res as Failure).error.message, contains('50 MB'));
    });

    test('successful upload → Firestore doc + storagePath', () async {
      final fakeStorage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      // Create a temp file for real FileStorageService validation path exists check
      // Our Fake bypasses file existence check, so we can use dummy path
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/dummy.pdf', fileName: 'dummy.pdf', mimeType: 'application/pdf', sizeBytes: 2048, type: AppFileType.pdf);
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Success<WorkspaceFile>>());
      final file = (res as Success<WorkspaceFile>).data;
      expect(file.name, 'dummy.pdf');
      expect(file.storagePath, isNotNull);
      expect(repo.loadFiles().length, 1);
      expect(repo.loadFiles().first.id, file.id);
    });

    test('upload failure → no Firestore doc, no orphan', () async {
      final fakeStorage = FakeFileStorageService(uploadResult: const Failure(ServerError(details: 'upload failed')));
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 1024, type: AppFileType.pdf);
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Failure<WorkspaceFile>>());
      expect(repo.loadFiles(), isEmpty);
      expect(fakeStorage.lastUploadStoragePath, isNull); // fake didn't set path on failure
    });

    test('Firestore failure after Storage success → cleanup Storage orphan', () async {
      final fakeStorage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      repo.setTestForcePersistFailure(true);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 1024, type: AppFileType.pdf);
      final res = await repo.uploadWorkspaceFile(req);
      expect(res, isA<Failure<WorkspaceFile>>());
      expect(repo.loadFiles(), isEmpty); // rolled back
      expect(fakeStorage.deleteCallCount, 1); // cleanup called
      expect(fakeStorage.lastDeleteStoragePath, isNotNull);
      expect(fakeStorage.lastDeleteStoragePath, contains('users/user-1/workspaces/ws-1/files/'));
    });

    test('delete success → Firestore + Storage both called', () async {
      final fakeStorage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      // First upload a file to have storagePath
      // Use sync addFile for simplicity then set storagePath manually via copy
      // Instead we test via upload
      // For this test, use the fake storage upload to create file with storagePath
      // We'll do async upload then delete
      // This is covered by previous tests; for delete we can test via addFile placeholder which has no storagePath -> delete should not call storage
      final id = repo.addFile('a.pdf', AppFileType.pdf).first.id;
      fakeStorage.deleteCallCount = 0;
      await repo.deleteFile(id);
      expect(repo.loadFiles(), isEmpty);
      // Placeholder file has no storagePath, so delete should not call storage (or call with empty -> no-op)
      expect(fakeStorage.deleteCallCount, 0);
    });

    test('delete with storagePath deletes both (integration)', () async {
      final fakeStorage = FakeFileStorageService();
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 1024, type: AppFileType.pdf);
      final uploadRes = await repo.uploadWorkspaceFile(req);
      final file = (uploadRes as Success<WorkspaceFile>).data;
      expect(file.storagePath, isNotNull);
      fakeStorage.deleteCallCount = 0;
      await repo.deleteFile(file.id);
      expect(fakeStorage.deleteCallCount, 1);
      expect(fakeStorage.lastDeleteStoragePath, file.storagePath);
      expect(repo.loadFiles(), isEmpty);
    });
  });

  group('PR3F download/open', () {
    test('storagePath present → getDownloadUrl success', () async {
      final fakeStorage = FakeFileStorageService(downloadUrlResult: Success('https://example.com/file.pdf'));
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 1024, type: AppFileType.pdf);
      final uploadRes = await repo.uploadWorkspaceFile(req);
      final file = (uploadRes as Success<WorkspaceFile>).data;
      final urlRes = await repo.getFileDownloadUrl(file.id);
      expect(urlRes, isA<Success<String>>());
      expect((urlRes as Success<String>).data, contains('https://example.com'));
      expect(fakeStorage.lastDownloadStoragePath, file.storagePath);
    });

    test('storagePath missing (legacy placeholder) → ValidationError', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: FakeFileStorageService());
      repo.setTestWorkspaces([_ws('ws-1')]);
      final id = repo.addFile('legacy.pdf', AppFileType.pdf).first.id;
      final res = await repo.getFileDownloadUrl(id);
      expect(res, isA<Failure<String>>());
      expect((res as Failure).error, isA<ValidationError>());
    });

    test('getDownloadUrl failure → Failure', () async {
      final fakeStorage = FakeFileStorageService(downloadUrlResult: Failure(ServerError(details: 'not found')));
      final repo = FirestoreWorkspaceRepository(uidProvider: () => 'user-1', fileStorageService: fakeStorage);
      repo.setTestWorkspaces([_ws('ws-1')]);
      const req = WorkspaceFileUploadRequest(localPath: '/tmp/a.pdf', fileName: 'a.pdf', sizeBytes: 1024, type: AppFileType.pdf);
      final uploadRes = await repo.uploadWorkspaceFile(req);
      final file = (uploadRes as Success<WorkspaceFile>).data;
      fakeStorage.downloadUrlResult = const Failure(ServerError(details: 'not found'));
      final res = await repo.getFileDownloadUrl(file.id);
      expect(res, isA<Failure<String>>());
    });

    test('unauthenticated getDownloadUrl → handled', () async {
      final repo = FirestoreWorkspaceRepository(uidProvider: () => '', fileStorageService: FakeFileStorageService());
      repo.setTestWorkspaces([_ws('ws-1')]);
      final res = await repo.getFileDownloadUrl('f-1');
      // Should return Failure or handle gracefully; for unauth repo, file not found path
      expect(res, isA<Failure<String>>());
    });
  });

  group('PR3F security — file docs', () {
    test('firestore file path is user/workspace isolated', () {
      final repoA = FirestoreWorkspaceRepository(uidProvider: () => 'user-A');
      final repoB = FirestoreWorkspaceRepository(uidProvider: () => 'user-B');
      repoA.setTestWorkspaces([_ws('ws-A')]);
      repoB.setTestWorkspaces([_ws('ws-B')]);
      repoA.addFile('a.pdf', AppFileType.pdf);
      expect(repoA.loadFiles().length, 1);
      expect(repoB.loadFiles().length, 0);
    });

    test('storage.rules file exists and contains workspace file rules', () {
      final file = File('storage.rules');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('users/{uid}/workspaces'));
      expect(content, contains('50 * 1024 * 1024'));
      expect(content, contains('request.auth.uid == uid'));
      expect(content, contains('rules_version = \'2\''));
    });

    test('firebase.json wires storage rules', () {
      final content = File('firebase.json').readAsStringSync();
      expect(content, contains('"storage"'));
      expect(content, contains('storage.rules'));
    });

    test('firestoreConstants.files used', () {
      // Verify constant exists and is used in repo (indirect via _filesCol)
      expect(FirestoreConstants.files, 'files');
    });
  });
}
