import 'package:flutter_test/flutter_test.dart';
import 'package:banataq/features/sync/domain/sync_operation.dart';

void main() {
  group('SyncOperation', () {
    test('creates operation with default values', () {
      final op = SyncOperation(
        userId: 'user1',
        collection: 'conversations',
        documentId: 'doc1',
        type: SyncOperationType.create,
        data: {'title': 'Test'},
      );

      expect(op.userId, 'user1');
      expect(op.collection, 'conversations');
      expect(op.documentId, 'doc1');
      expect(op.type, SyncOperationType.create);
      expect(op.data, {'title': 'Test'});
      expect(op.status, SyncStatus.pending);
      expect(op.retryCount, 0);
      expect(op.id, isNotEmpty);
      expect(op.createdAt, isNotNull);
    });

    test('firestorePath with parent collection', () {
      final op = SyncOperation(
        userId: 'user1',
        collection: 'messages',
        documentId: 'msg1',
        type: SyncOperationType.create,
        parentCollection: 'conversations',
        parentId: 'conv1',
      );

      expect(op.firestorePath, 'conversations/conv1/messages/msg1');
    });

    test('firestorePath without parent collection', () {
      final op = SyncOperation(
        userId: 'user1',
        collection: 'conversations',
        documentId: 'conv1',
        type: SyncOperationType.create,
      );

      expect(op.firestorePath, 'conversations/conv1');
    });

    test('copyWith updates fields', () {
      final op = SyncOperation(
        userId: 'user1',
        collection: 'conversations',
        documentId: 'doc1',
        type: SyncOperationType.create,
      );

      final now = DateTime.now();
      final updated = op.copyWith(
        status: SyncStatus.failed,
        retryCount: 3,
        lastError: 'Network error',
        lastAttemptAt: now,
      );

      expect(updated.status, SyncStatus.failed);
      expect(updated.retryCount, 3);
      expect(updated.lastError, 'Network error');
      expect(updated.lastAttemptAt, now);
      expect(updated.id, op.id);
      expect(updated.userId, op.userId);
    });

    test('toJson and fromJson roundtrip', () {
      final original = SyncOperation(
        id: 'test-id-123',
        userId: 'user1',
        collection: 'conversations',
        documentId: 'conv1',
        type: SyncOperationType.update,
        data: {'title': 'Hello', 'messageCount': 3},
        parentCollection: null,
        parentId: null,
        createdAt: DateTime(2026, 7, 25, 12, 0, 0),
        retryCount: 2,
        status: SyncStatus.failed,
        lastError: 'Server error',
        lastAttemptAt: DateTime(2026, 7, 25, 12, 5, 0),
      );

      final json = original.toJson();
      final restored = SyncOperation.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.collection, original.collection);
      expect(restored.documentId, original.documentId);
      expect(restored.type, original.type);
      expect(restored.data, original.data);
      expect(restored.parentCollection, original.parentCollection);
      expect(restored.parentId, original.parentId);
      expect(restored.createdAt, original.createdAt);
      expect(restored.retryCount, original.retryCount);
      expect(restored.status, original.status);
      expect(restored.lastError, original.lastError);
      expect(restored.lastAttemptAt, original.lastAttemptAt);
    });

    test('toJson and fromJson with null lastError and lastAttemptAt', () {
      final op = SyncOperation(
        userId: 'user1',
        collection: 'conversations',
        documentId: 'conv1',
        type: SyncOperationType.create,
      );

      final json = op.toJson();
      final restored = SyncOperation.fromJson(json);

      expect(restored.id, op.id);
      expect(restored.status, SyncStatus.pending);
      expect(restored.lastError, isNull);
      expect(restored.lastAttemptAt, isNull);
    });

    test('all SyncOperationType values are handled', () {
      expect(SyncOperationType.values.length, 3);
      expect(SyncOperationType.values, containsAll([
        SyncOperationType.create,
        SyncOperationType.update,
        SyncOperationType.delete,
      ]));
    });

    test('all SyncStatus values are handled', () {
      expect(SyncStatus.values.length, 4);
      expect(SyncStatus.values, containsAll([
        SyncStatus.pending,
        SyncStatus.inProgress,
        SyncStatus.completed,
        SyncStatus.failed,
      ]));
    });

    test('toString returns expected format', () {
      final op = SyncOperation(
        userId: 'user1',
        collection: 'conversations',
        documentId: 'conv1',
        type: SyncOperationType.update,
      );

      expect(op.toString(), contains('SyncOp'));
      expect(op.toString(), contains('update'));
      expect(op.toString(), contains('conversations/conv1'));
    });
  });
}
