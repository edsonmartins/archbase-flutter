/// Retrato agregado do estado de sincronização (para badges/contador/progresso).
library;

/// Snapshot imutável do motor, exposto por `ValueListenable` para a UI.
class ArchbaseSyncSnapshot {
  const ArchbaseSyncSnapshot({
    this.isSyncing = false,
    this.pending = 0,
    this.sending = 0,
    this.failed = 0,
    this.conflict = 0,
    this.exhausted = 0,
    this.blocked = 0,
    this.progress = 1.0,
    this.lastSyncAt,
    this.lastError,
  });

  final bool isSyncing;
  final int pending;
  final int sending;
  final int failed;
  final int conflict;
  final int exhausted;
  final int blocked;

  /// 0.0..1.0 do drain corrente (1.0 quando não há nada em voo).
  final double progress;
  final DateTime? lastSyncAt;
  final String? lastError;

  /// Backlog "em aberto" que ainda tende a sincronizar sozinho.
  int get backlog => pending + sending + blocked;

  /// Itens que exigem ação do usuário (erro terminal).
  int get needsAttention => conflict + exhausted + failed;

  ArchbaseSyncSnapshot copyWith({
    bool? isSyncing,
    int? pending,
    int? sending,
    int? failed,
    int? conflict,
    int? exhausted,
    int? blocked,
    double? progress,
    DateTime? lastSyncAt,
    String? lastError,
    bool clearError = false,
  }) {
    return ArchbaseSyncSnapshot(
      isSyncing: isSyncing ?? this.isSyncing,
      pending: pending ?? this.pending,
      sending: sending ?? this.sending,
      failed: failed ?? this.failed,
      conflict: conflict ?? this.conflict,
      exhausted: exhausted ?? this.exhausted,
      blocked: blocked ?? this.blocked,
      progress: progress ?? this.progress,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}
