import 'package:uuid/uuid.dart';

enum SyncOperationType { create, update, delete }

enum SyncStatus { pending, inProgress, completed, failed }

final class SyncOperation {
  final String id;
  final String userId;
  final String collection;
  final String documentId;
  final SyncOperationType type;
  final Map<String, dynamic> data;
  final String? parentCollection;
  final String? parentId;
  final DateTime createdAt;
  int retryCount;
  SyncStatus status;
  String? lastError;
  DateTime? lastAttemptAt;

  SyncOperation({
    required this.userId,
    required this.collection,
    required this.documentId,
    required this.type,
    this.data = const {},
    this.parentCollection,
    this.parentId,
    String? id,
    DateTime? createdAt,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.lastError,
    this.lastAttemptAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  String get firestorePath {
    if (parentCollection != null && parentId != null) {
      return '$parentCollection/$parentId/$collection/$documentId';
    }
    return '$collection/$documentId';
  }

  SyncOperation copyWith({
    SyncStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? lastAttemptAt,
  }) {
    return SyncOperation(
      id: id,
      userId: userId,
      collection: collection,
      documentId: documentId,
      type: type,
      data: data,
      parentCollection: parentCollection,
      parentId: parentId,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'collection': collection,
        'documentId': documentId,
        'type': type.name,
        'data': data,
        'parentCollection': parentCollection,
        'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'status': status.name,
        'lastError': lastError,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      userId: json['userId'] as String,
      collection: json['collection'] as String,
      documentId: json['documentId'] as String,
      type: SyncOperationType.values.firstWhere((e) => e.name == json['type']),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      parentCollection: json['parentCollection'] as String?,
      parentId: json['parentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      status: SyncStatus.values.firstWhere((e) => e.name == json['status']),
      lastError: json['lastError'] as String?,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
    );
  }

  @override
  String toString() => 'SyncOp($type $firestorePath [$status] retry=$retryCount)';
}
