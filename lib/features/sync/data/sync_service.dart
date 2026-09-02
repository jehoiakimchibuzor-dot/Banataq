import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/sync_operation.dart';
import '../domain/sync_metrics.dart';
import 'sync_engine.dart';
import '../../../../core/network/connectivity_service.dart';

final class SyncService {
  late final SyncEngine _engine;
  bool _initialized = false;

  Stream<SyncMetrics> get metrics => _engine.metrics;
  SyncMetrics get currentMetrics => _engine.currentMetrics;

  Future<void> initialize({
    required SharedPreferences prefs,
    required ConnectivityService connectivityService,
    FirebaseFirestore? firestore,
  }) async {
    _engine = SyncEngine(
      prefs: prefs,
      connectivityService: connectivityService,
      firestore: firestore,
    );
    await _engine.initialize();
    _initialized = true;
  }

  Future<void> syncConversation({
    required String userId,
    required String conversationId,
    required Map<String, dynamic> data,
    SyncOperationType type = SyncOperationType.create,
  }) async {
    await _ensureInitialized();
    await _engine.enqueue(SyncOperation(
      userId: userId,
      collection: 'conversations',
      documentId: conversationId,
      type: type,
      data: data,
    ));
  }

  Future<void> syncMessage({
    required String userId,
    required String conversationId,
    required String messageId,
    required Map<String, dynamic> data,
    SyncOperationType type = SyncOperationType.create,
  }) async {
    await _ensureInitialized();
    await _engine.enqueue(SyncOperation(
      userId: userId,
      collection: 'messages',
      documentId: messageId,
      type: type,
      data: data,
      parentCollection: 'conversations',
      parentId: conversationId,
    ));
  }

  Future<void> syncProfile({
    required String userId,
    required Map<String, dynamic> data,
    SyncOperationType type = SyncOperationType.update,
  }) async {
    await _ensureInitialized();
    await _engine.enqueue(SyncOperation(
      userId: userId,
      collection: 'users',
      documentId: userId,
      type: type,
      data: data,
    ));
  }

  Future<void> syncSettings({
    required String userId,
    required Map<String, dynamic> data,
    SyncOperationType type = SyncOperationType.update,
  }) async {
    await _ensureInitialized();
    await _engine.enqueue(SyncOperation(
      userId: userId,
      collection: 'settings',
      documentId: userId,
      type: type,
      data: data,
    ));
  }

  Future<void> syncSavedItem({
    required String userId,
    required String itemId,
    required Map<String, dynamic> data,
    SyncOperationType type = SyncOperationType.create,
  }) async {
    await _ensureInitialized();
    await _engine.enqueue(SyncOperation(
      userId: userId,
      collection: 'saved_items',
      documentId: itemId,
      type: type,
      data: data,
    ));
  }

  Future<void> processQueue() async {
    await _ensureInitialized();
    await _engine.processQueue();
  }

  Future<SyncMetrics> getMetrics() async {
    return currentMetrics;
  }

  Future<void> retryFailed() async {
    await _ensureInitialized();
    await _engine.processQueue();
  }

  Future<void> dispose() async {
    if (_initialized) {
      await _engine.dispose();
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      throw StateError('SyncService not initialized. Call initialize() first.');
    }
  }
}
