final class SyncMetrics {
  final int queueSize;
  final int pendingCount;
  final int inProgressCount;
  final int failedCount;
  final int completedCount;
  final int totalRetries;
  final DateTime? lastSuccessfulSyncAt;
  final Duration? averageSyncDuration;
  final bool isProcessing;
  final String? lastErrorMessage;

  const SyncMetrics({
    this.queueSize = 0,
    this.pendingCount = 0,
    this.inProgressCount = 0,
    this.failedCount = 0,
    this.completedCount = 0,
    this.totalRetries = 0,
    this.lastSuccessfulSyncAt,
    this.averageSyncDuration,
    this.isProcessing = false,
    this.lastErrorMessage,
  });

  SyncMetrics copyWith({
    int? queueSize,
    int? pendingCount,
    int? inProgressCount,
    int? failedCount,
    int? completedCount,
    int? totalRetries,
    DateTime? lastSuccessfulSyncAt,
    Duration? averageSyncDuration,
    bool? isProcessing,
    String? lastErrorMessage,
  }) {
    return SyncMetrics(
      queueSize: queueSize ?? this.queueSize,
      pendingCount: pendingCount ?? this.pendingCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      failedCount: failedCount ?? this.failedCount,
      completedCount: completedCount ?? this.completedCount,
      totalRetries: totalRetries ?? this.totalRetries,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      averageSyncDuration: averageSyncDuration ?? this.averageSyncDuration,
      isProcessing: isProcessing ?? this.isProcessing,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }

  @override
  String toString() => 'SyncMetrics(queue=$queueSize pending=$pendingCount '
      'failed=$failedCount lastSync=$lastSuccessfulSyncAt)';
}
