/// Operação de outbox do módulo `archbase_offline`.
///
/// Uma linha por mutação pendente. Prefixada `Archbase*` para não colidir com o
/// `SyncOperation` legado (fila HTTP genérica). Enums serializados por [name].
library;

import 'archbase_binary_uploader.dart';

/// Estado de uma [ArchbaseSyncOperation] na fila (persistido por [name]).
enum ArchbaseSyncOpStatus {
  /// Na fila, aguardando drain.
  pending,

  /// Enviada no batch atual (em voo).
  sending,

  /// ACK de sucesso.
  processed,

  /// Idempotência: já processada antes (sucesso, sem reexecutar).
  skipped,

  /// ACK de conflito (versão/estado) — exige resolução.
  conflict,

  /// Erro transitório — retry com backoff.
  failed,

  /// Dead-letter: esgotou as tentativas — exige reenvio manual.
  exhausted,

  /// Dependência ainda não concluída — não enviada.
  blocked,

  /// Tipo não suportado pelo servidor — erro de contrato.
  rejected;

  /// Terminal de sucesso (pode ser removida da fila).
  bool get isDoneOk =>
      this == ArchbaseSyncOpStatus.processed ||
      this == ArchbaseSyncOpStatus.skipped;

  /// Terminal de erro (fica para ação do usuário/resolução).
  bool get isTerminalError =>
      this == ArchbaseSyncOpStatus.conflict ||
      this == ArchbaseSyncOpStatus.exhausted ||
      this == ArchbaseSyncOpStatus.rejected;

  /// Está na fila aguardando (pode ser reavaliada num próximo ciclo).
  bool get isPendingLike =>
      this == ArchbaseSyncOpStatus.pending ||
      this == ArchbaseSyncOpStatus.failed ||
      this == ArchbaseSyncOpStatus.blocked;
}

/// Operação idempotente de mutação enfileirada para envio em batch.
class ArchbaseSyncOperation {
  const ArchbaseSyncOperation({
    required this.id,
    required this.type,
    required this.aggregateId,
    required this.payload,
    required this.clientCreatedAt,
    this.baseVersion,
    this.dependsOn,
    this.status = ArchbaseSyncOpStatus.pending,
    this.attempts = 0,
    this.nextRetryAt,
    this.lastError,
    this.processedAt,
    this.ackResponse,
    this.binaries = const [],
  });

  /// UUID da operação. É também a `idempotencyKey` (estável em retries).
  final String id;

  /// Tipo de operação registrado pelo app (ex.: `VISIT_CHECK_IN`).
  final String type;

  /// Id do modelo de domínio afetado.
  final String aggregateId;

  /// JSON (contrato do backend) já serializado.
  final Map<String, dynamic> payload;

  final DateTime clientCreatedAt;

  /// `serverVersion` conhecido no momento da operação (detecção de conflito).
  final int? baseVersion;

  /// Id de outra operação que precisa concluir antes desta.
  final String? dependsOn;

  final ArchbaseSyncOpStatus status;
  final int attempts;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime? processedAt;
  final Map<String, dynamic>? ackResponse;

  /// Binários (foto/assinatura) que precisam subir para a entidade fechar.
  final List<ArchbaseOpBinary> binaries;

  /// Ainda há binário pendente de upload (gating).
  bool get hasPendingBinaries => binaries.any((b) => !b.isUploaded);

  ArchbaseSyncOperation copyWith({
    ArchbaseSyncOpStatus? status,
    int? attempts,
    DateTime? nextRetryAt,
    String? lastError,
    DateTime? processedAt,
    Map<String, dynamic>? ackResponse,
    List<ArchbaseOpBinary>? binaries,
    bool clearNextRetryAt = false,
    bool clearLastError = false,
  }) {
    return ArchbaseSyncOperation(
      id: id,
      type: type,
      aggregateId: aggregateId,
      payload: payload,
      clientCreatedAt: clientCreatedAt,
      baseVersion: baseVersion,
      dependsOn: dependsOn,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextRetryAt:
          clearNextRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      processedAt: processedAt ?? this.processedAt,
      ackResponse: ackResponse ?? this.ackResponse,
      binaries: binaries ?? this.binaries,
    );
  }
}
