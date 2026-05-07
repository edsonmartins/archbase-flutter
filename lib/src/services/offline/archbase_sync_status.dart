/// Estado agregado da fila de sincronização offline.
class ArchbaseSyncStatus {
  const ArchbaseSyncStatus({
    this.isSyncing = false,
    this.pending = 0,
    this.lastSyncAt,
    this.lastError,
  });

  final bool isSyncing;
  final int pending;
  final DateTime? lastSyncAt;
  final String? lastError;

  bool get hasPending => pending > 0;
  bool get hasError => lastError != null;

  ArchbaseSyncStatus copyWith({
    bool? isSyncing,
    int? pending,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return ArchbaseSyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      pending: pending ?? this.pending,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
