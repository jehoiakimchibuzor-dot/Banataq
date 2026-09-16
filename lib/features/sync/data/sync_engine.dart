import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sync_operation.dart';
import '../domain/sync_metrics.dart';
import 'sync_queue_manager.dart';
import 'sync_conflict_resolver.dart';
import '../../../../core/network/connectivity_service.dart';

final class SyncEngine {
  final SyncQueueManager _queueManager;
  final SyncConflictResolver _conflictResolver;
  final ConnectivityService connectivityService;
  final FirebaseFirestore _firestore;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isProcessing = false;
  Timer? _retryTimer;

  final _metricsController = StreamController<SyncMetrics>.broadcast();
  Stream<SyncMetrics> get metrics => _metricsController.stream;

  SyncMetrics _lastMetrics = const SyncMetrics();
  SyncMetrics get currentMetrics => _lastMetrics;

  SyncEngine({
    required SharedPreferences prefs,
    required this.connectivityService,
    FirebaseFirestore? firestore,
  })  : _queueManager = SyncQueueManager(prefs: prefs),
        _conflictResolver = SyncConflictResolver(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          processQueue();
        }
      },
    );

    final connected = await connectivityService.isConnected;
    if (connected) {
      await processQueue();
    }

    _emitMetrics();
  }

  Future<void> enqueue(SyncOperation operation) async {
    final existing = await _isDuplicate(operation);
    if (existing) return;

    await _queueManager.enqueue(operation);
    _emitMetrics();

    final connected = await connectivityService.isConnected;
    if (connected) {
      unawaited(processQueue());
    }
  }

  Future<void> enqueueAll(List<SyncOperation> operations) async {
    for (final op in operations) {
      await enqueue(op);
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    _emitMetrics();

    try {
      while (await _queueManager.hasPendingOperations()) {
        final batch = await _queueManager.dequeue(batchSize: 5);
        if (batch.isEmpty) break;

        final opsToRetry = <SyncOperation>[];

        for (final operation in batch) {
          final bool applied = await _applyOperation(operation);
          if (!applied) {
            opsToRetry.add(operation);
          }
        }

        for (final operation in batch) {
          if (!opsToRetry.contains(operation)) {
            await _queueManager.markCompleted(operation.id);
          }
        }

        for (final op in opsToRetry) {
          if (op.retryCount >= 5) {
            await _queueManager.markFailed(op.id, 'Max retries exceeded');
          } else {
            await _queueManager.markForRetry(op);
          }
        }
      }

      _emitMetrics();
    } finally {
      _isProcessing = false;
      _emitMetrics();

      final List<SyncOperation> hasFailed = await _queueManager.getFailedOperations();
      if (hasFailed.isNotEmpty) {
        _scheduleRetry();
      }
    }
  }

  /// Resets failed ops (retryCount < 5) to pending and re-processes.
  Future<void> retryFailed() async {
    await _queueManager.retryFailed();
    _emitMetrics();
    final bool connected = await connectivityService.isConnected;
    if (connected) {
      await processQueue();
    }
  }

  Future<bool> _applyOperation(SyncOperation operation) async {
    try {
      switch (operation.type) {
        case SyncOperationType.create:
          final bool canCreate = await _conflictResolver.canCreate(
            operation: operation,
            firestore: _firestore,
          );
          if (!canCreate) return true;
          final DocumentReference<Map<String, dynamic>> docRef = _getDocumentRef(operation);
          await docRef.set(operation.data, SetOptions(merge: true));
          return true;

        case SyncOperationType.update:
          final Map<String, dynamic>? resolved = await _conflictResolver.resolve(
            operation: operation,
            firestore: _firestore,
          );
          if (resolved == null) return true;
          final DocumentReference<Map<String, dynamic>> docRef = _getDocumentRef(operation);
          await docRef.set(resolved, SetOptions(merge: true));
          return true;

        case SyncOperationType.delete:
          final DocumentReference<Map<String, dynamic>> docRef = _getDocumentRef(operation);
          await docRef.delete();
          return true;
      }
    } catch (e) {
      operation.lastError = e.toString();
      operation.lastAttemptAt = DateTime.now();
      return false;
    }
  }

  Future<bool> _isDuplicate(SyncOperation operation) async {
    final pending = await _queueManager.getPendingOperations();
    return pending.any((op) =>
        op.collection == operation.collection &&
        op.documentId == operation.documentId &&
        op.type == operation.type);
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      processQueue();
    });
  }

  DocumentReference<Map<String, dynamic>> _getDocumentRef(SyncOperation operation) {
    if (operation.parentCollection != null && operation.parentId != null) {
      return _firestore
          .collection(operation.parentCollection!)
          .doc(operation.parentId!)
          .collection(operation.collection)
          .doc(operation.documentId);
    }
    return _firestore.collection(operation.collection).doc(operation.documentId);
  }

  void _emitMetrics() {
    _queueManager.getMetrics().then((metrics) {
      _lastMetrics = metrics.copyWith(
        isProcessing: _isProcessing,
      );
      _metricsController.add(_lastMetrics);
    });
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    await _metricsController.close();
  }
}
