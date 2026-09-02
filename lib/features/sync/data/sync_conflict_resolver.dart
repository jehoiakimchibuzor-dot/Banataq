import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/sync_operation.dart';

final class SyncConflictResolver {
  static const String _updatedAtField = 'updatedAt';

  /// Resolves a conflict between local and remote data.
  /// Strategy: last-write-wins based on [updatedAt] timestamp.
  /// Returns the data that should be written to Firestore.
  Future<Map<String, dynamic>?> resolve({
    required SyncOperation operation,
    required FirebaseFirestore firestore,
  }) async {
    final docRef = _getDocumentReference(firestore, operation);

    try {
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        if (operation.type == SyncOperationType.delete) {
          return null;
        }
        return operation.data;
      }

      if (operation.type == SyncOperationType.delete) {
        return null;
      }

      final remoteData = snapshot.data() as Map<String, dynamic>;
      final localTimestamp = extractTimestamp(operation.data);
      final remoteTimestamp = extractTimestamp(remoteData);

      if (localTimestamp == null && remoteTimestamp != null) {
        return null;
      }

      if (remoteTimestamp == null && localTimestamp != null) {
        return operation.data;
      }

      if (localTimestamp != null && remoteTimestamp != null) {
        if (!localTimestamp.isAfter(remoteTimestamp)) {
          return null;
        }
      }

      return mergeData(remoteData, operation.data);
    } catch (_) {
      return operation.data;
    }
  }

  /// For create operations, check if document already exists to prevent duplicates.
  Future<bool> canCreate({
    required SyncOperation operation,
    required FirebaseFirestore firestore,
  }) async {
    try {
      final docRef = _getDocumentReference(firestore, operation);
      final snapshot = await docRef.get();
      return !snapshot.exists;
    } catch (_) {
      return true;
    }
  }

  @visibleForTesting
  DateTime? extractTimestamp(Map<String, dynamic> data) {
    final value = data[_updatedAtField];
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @visibleForTesting
  Map<String, dynamic> mergeData(
    Map<String, dynamic> remote,
    Map<String, dynamic> local,
  ) {
    final merged = Map<String, dynamic>.from(remote);
    for (final entry in local.entries) {
      merged[entry.key] = entry.value;
    }
    return merged;
  }

  DocumentReference _getDocumentReference(
    FirebaseFirestore firestore,
    SyncOperation operation,
  ) {
    if (operation.parentCollection != null && operation.parentId != null) {
      return firestore
          .collection(operation.parentCollection!)
          .doc(operation.parentId!)
          .collection(operation.collection)
          .doc(operation.documentId);
    }
    return firestore.collection(operation.collection).doc(operation.documentId);
  }
}
