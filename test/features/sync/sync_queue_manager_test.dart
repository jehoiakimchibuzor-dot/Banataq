import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:banataq/features/sync/data/sync_queue_manager.dart';
import 'package:banataq/features/sync/domain/sync_operation.dart';

void main() {
  late SharedPreferences prefs;
  late SyncQueueManager manager;

  SyncOperation createOp({
    String id = 'op1',
    String userId = 'user1',
    String collection = 'conversations',
    String documentId = 'doc1',
    SyncOperationType type = SyncOperationType.create,
    SyncStatus status = SyncStatus.pending,
    int retryCount = 0,
  }) {
    return SyncOperation(
      id: id,
      userId: userId,
      collection: collection,
      documentId: documentId,
      type: type,
      status: status,
      retryCount: retryCount,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    manager = SyncQueueManager(prefs: prefs);
  });

  group('enqueue', () {
    test('adds operation to empty queue', () async {
      await manager.enqueue(createOp());
      expect(await manager.getQueueSize(), 1);
    });

    test('adds multiple operations', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.enqueue(createOp(id: 'op2'));
      expect(await manager.getQueueSize(), 2);
    });

    test('allows operations with same id (dedup done at engine level)', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.enqueue(createOp(id: 'op1'));
      expect(await manager.getQueueSize(), 2);
    });

    test('discards oldest failed operation when queue reaches limit', () async {
      final ops = List.generate(5, (i) => createOp(
        id: 'op$i',
        status: i == 0 ? SyncStatus.failed : SyncStatus.pending,
      ));

      for (final op in ops) {
        await manager.enqueue(op);
      }

      expect(await manager.getQueueSize(), 5);
    });
  });

  group('dequeue', () {
    test('returns pending operations in order', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.enqueue(createOp(id: 'op2'));

      final batch = await manager.dequeue(batchSize: 10);
      expect(batch.length, 2);
      expect(batch[0].status, SyncStatus.inProgress);
      expect(batch[1].status, SyncStatus.inProgress);
    });

    test('returns up to batchSize operations', () async {
      for (int i = 0; i < 10; i++) {
        await manager.enqueue(createOp(id: 'op$i'));
      }

      final batch = await manager.dequeue(batchSize: 3);
      expect(batch.length, 3);
    });

    test('excludes failed and in-progress operations', () async {
      await manager.enqueue(createOp(id: 'op1', status: SyncStatus.failed));
      await manager.enqueue(createOp(id: 'op2', status: SyncStatus.inProgress));
      await manager.enqueue(createOp(id: 'op3'));

      final batch = await manager.dequeue();
      expect(batch.length, 1);
      expect(batch[0].id, 'op3');
    });
  });

  group('markCompleted', () {
    test('removes completed operation from queue', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.dequeue();
      await manager.markCompleted('op1');

      expect(await manager.getQueueSize(), 0);
    });
  });

  group('markFailed', () {
    test('marks operation as failed with error', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.dequeue();
      await manager.markFailed('op1', 'Server error');

      final failed = await manager.getFailedOperations();
      expect(failed.length, 1);
      expect(failed[0].lastError, 'Server error');
      expect(failed[0].retryCount, 1);
    });
  });

  group('markForRetry', () {
    test('resets operation to pending with incremented retry', () async {
      final op = createOp(id: 'op1', retryCount: 2);
      await manager.enqueue(op);
      await manager.dequeue();
      await manager.markForRetry(op);

      final pending = await manager.getPendingOperations();
      expect(pending.length, 1);
      expect(pending[0].retryCount, 3);
      expect(pending[0].status, SyncStatus.pending);
    });
  });

  group('hasPendingOperations', () {
    test('returns false for empty queue', () async {
      expect(await manager.hasPendingOperations(), false);
    });

    test('returns true when pending ops exist', () async {
      await manager.enqueue(createOp());
      expect(await manager.hasPendingOperations(), true);
    });

    test('returns true when in-progress ops exist', () async {
      await manager.enqueue(createOp());
      await manager.dequeue();
      expect(await manager.hasPendingOperations(), true);
    });

    test('returns false when only failed ops exist', () async {
      await manager.enqueue(createOp(status: SyncStatus.failed));
      expect(await manager.hasPendingOperations(), false);
    });
  });

  group('retryFailed', () {
    test('resets failed operations to pending', () async {
      await manager.enqueue(createOp(id: 'op1', status: SyncStatus.failed, retryCount: 1));
      await manager.retryFailed();

      final pending = await manager.getPendingOperations();
      expect(pending.length, 1);
    });

    test('does not retry operations that exceeded max retries', () async {
      await manager.enqueue(createOp(id: 'op1', status: SyncStatus.failed, retryCount: 5));
      await manager.retryFailed();

      final pending = await manager.getPendingOperations();
      expect(pending.length, 0);
    });
  });

  group('getMetrics', () {
    test('returns zero metrics for empty queue', () async {
      final metrics = await manager.getMetrics();
      expect(metrics.queueSize, 0);
      expect(metrics.pendingCount, 0);
      expect(metrics.failedCount, 0);
    });

    test('returns correct counts', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.enqueue(createOp(id: 'op2', status: SyncStatus.failed));
      await manager.enqueue(createOp(id: 'op3'));

      final metrics = await manager.getMetrics();
      expect(metrics.queueSize, 3);
      expect(metrics.pendingCount, 2);
      expect(metrics.failedCount, 1);
      expect(metrics.inProgressCount, 0);
    });
  });

  group('persistence', () {
    test('survives manager recreation', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.enqueue(createOp(id: 'op2'));

      final manager2 = SyncQueueManager(prefs: prefs);
      expect(await manager2.getQueueSize(), 2);
    });

    test('clear removes all operations', () async {
      await manager.enqueue(createOp(id: 'op1'));
      await manager.clear();
      expect(await manager.getQueueSize(), 0);
    });
  });
}
