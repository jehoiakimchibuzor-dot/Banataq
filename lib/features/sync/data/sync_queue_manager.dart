import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sync_operation.dart';
import '../domain/sync_metrics.dart';

final class SyncQueueManager {
  final SharedPreferences prefs;

  static const _queueKey = 'sync_queue';
  static const _maxQueueSize = 1000;

  SyncQueueManager({required this.prefs});

  Future<void> enqueue(SyncOperation operation) async {
    final queue = await _loadAll();
    if (queue.length >= _maxQueueSize) {
      final oldest = queue
          .where((op) => op.status == SyncStatus.failed)
          .fold<SyncOperation?>(null, (prev, op) {
        if (prev == null || op.createdAt.isBefore(prev.createdAt)) return op;
        return prev;
      });

      if (oldest != null) {
        queue.remove(oldest);
      } else {
        return;
      }
    }

    queue.add(operation);
    await _saveAll(queue);
  }

  Future<List<SyncOperation>> dequeue({int batchSize = 10}) async {
    final queue = await _loadAll();
    final batch = queue
        .where((op) => op.status == SyncStatus.pending)
        .take(batchSize)
        .toList();

    for (final op in batch) {
      op.status = SyncStatus.inProgress;
    }

    await _saveAll(queue);
    return batch;
  }

  Future<void> markCompleted(String operationId) async {
    final queue = await _loadAll();
    queue.removeWhere((op) => op.id == operationId);
    await _saveAll(queue);
  }

  Future<void> markFailed(String operationId, String error) async {
    final queue = await _loadAll();
    final index = queue.indexWhere((op) => op.id == operationId);
    if (index >= 0) {
      queue[index] = queue[index].copyWith(
        status: SyncStatus.failed,
        lastError: error,
        lastAttemptAt: DateTime.now(),
        retryCount: queue[index].retryCount + 1,
      );
      await _saveAll(queue);
    }
  }

  Future<void> markForRetry(SyncOperation operation) async {
    final queue = await _loadAll();
    final index = queue.indexWhere((op) => op.id == operation.id);
    if (index >= 0) {
      queue[index] = operation.copyWith(
        status: SyncStatus.pending,
        lastAttemptAt: DateTime.now(),
        retryCount: operation.retryCount + 1,
      );
      await _saveAll(queue);
    }
  }

  Future<List<SyncOperation>> getFailedOperations() async {
    final queue = await _loadAll();
    return queue.where((op) => op.status == SyncStatus.failed).toList();
  }

  Future<List<SyncOperation>> getPendingOperations() async {
    final queue = await _loadAll();
    return queue.where((op) => op.status == SyncStatus.pending).toList();
  }

  Future<int> getQueueSize() async {
    final queue = await _loadAll();
    return queue.length;
  }

  Future<bool> hasPendingOperations() async {
    final queue = await _loadAll();
    return queue.any((op) =>
        op.status == SyncStatus.pending || op.status == SyncStatus.inProgress);
  }

  Future<void> retryFailed() async {
    final queue = await _loadAll();
    for (int i = 0; i < queue.length; i++) {
      if (queue[i].status == SyncStatus.failed && queue[i].retryCount < 5) {
        queue[i] = queue[i].copyWith(status: SyncStatus.pending);
      }
    }
    await _saveAll(queue);
  }

  Future<void> clear() async {
    await prefs.remove(_queueKey);
  }

  Future<SyncMetrics> getMetrics() async {
    final queue = await _loadAll();
    final pending = queue.where((op) => op.status == SyncStatus.pending).length;
    final inProgress = queue.where((op) => op.status == SyncStatus.inProgress).length;
    final failed = queue.where((op) => op.status == SyncStatus.failed).length;
    final completed = queue.where((op) => op.status == SyncStatus.completed).length;
    final totalRetries = queue.fold<int>(0, (sum, op) => sum + op.retryCount);
    final lastSuccessAt = queue
        .where((op) => op.status == SyncStatus.completed)
        .map((op) => op.lastAttemptAt)
        .whereType<DateTime>()
        .fold<DateTime?>(null, (prev, dt) =>
            prev == null || dt.isAfter(prev) ? dt : prev);

    return SyncMetrics(
      queueSize: queue.length,
      pendingCount: pending,
      inProgressCount: inProgress,
      failedCount: failed,
      completedCount: completed,
      totalRetries: totalRetries,
      lastSuccessfulSyncAt: lastSuccessAt,
    );
  }

  Future<List<SyncOperation>> _loadAll() async {
    final raw = prefs.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<SyncOperation> operations) async {
    final json = jsonEncode(operations.map((op) => op.toJson()).toList());
    await prefs.setString(_queueKey, json);
  }
}
