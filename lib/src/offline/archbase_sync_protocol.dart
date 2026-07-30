/// Protocolo de rede do batch `POST /api/v1/sync/operations`.
///
/// Define o corpo enviado e o ACK por operação. O status vem UPPERCASE no fio e
/// é mapeado para [ArchbaseSyncOpStatus].
library;

import 'archbase_sync_operation.dart';

/// Resultado (ACK) de uma operação, devolvido pelo servidor.
class ArchbaseSyncAck {
  const ArchbaseSyncAck({
    required this.id,
    required this.status,
    this.serverVersion,
    this.error,
    this.dependsOn,
    this.conflict,
  });

  final String id;
  final ArchbaseSyncOpStatus status;
  final int? serverVersion;
  final String? error;
  final String? dependsOn;
  final Map<String, dynamic>? conflict;

  factory ArchbaseSyncAck.fromJson(Map<String, dynamic> json) {
    return ArchbaseSyncAck(
      id: json['id'] as String,
      status: _statusFromWire(json['status'] as String?),
      serverVersion: (json['serverVersion'] as num?)?.toInt(),
      error: json['error'] as String?,
      dependsOn: json['dependsOn'] as String?,
      conflict: (json['conflict'] as Map?)?.cast<String, dynamic>(),
    );
  }

  static ArchbaseSyncOpStatus _statusFromWire(String? wire) {
    switch ((wire ?? '').toUpperCase()) {
      case 'PROCESSED':
        return ArchbaseSyncOpStatus.processed;
      case 'SKIPPED':
        return ArchbaseSyncOpStatus.skipped;
      case 'CONFLICT':
        return ArchbaseSyncOpStatus.conflict;
      case 'BLOCKED':
        return ArchbaseSyncOpStatus.blocked;
      case 'REJECTED':
        return ArchbaseSyncOpStatus.rejected;
      case 'FAILED':
        return ArchbaseSyncOpStatus.failed;
      default:
        // Desconhecido = tratamos como falha transitória (conservador).
        return ArchbaseSyncOpStatus.failed;
    }
  }
}

/// Resposta do batch: um ACK por operação enviada.
class ArchbaseSyncBatchResponse {
  const ArchbaseSyncBatchResponse({required this.acks, this.serverTime});

  final List<ArchbaseSyncAck> acks;
  final DateTime? serverTime;

  factory ArchbaseSyncBatchResponse.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List? ?? const [])
        .cast<Map>()
        .map((m) => ArchbaseSyncAck.fromJson(m.cast<String, dynamic>()))
        .toList();
    return ArchbaseSyncBatchResponse(
      acks: results,
      serverTime: _parseDate(json['serverTime']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// Resposta da reconciliação por transação (`POST /sync/operations/status`):
/// dos ids perguntados, quais JÁ FORAM processados no servidor (estão no ledger).
class ArchbaseSyncStatusResponse {
  const ArchbaseSyncStatusResponse({required this.processed});

  /// operationIds já processados (o cliente marca esses como sincronizados).
  final List<String> processed;

  factory ArchbaseSyncStatusResponse.fromJson(Map<String, dynamic> json) {
    return ArchbaseSyncStatusResponse(
      processed: (json['processed'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Serializa uma operação para o corpo do batch.
Map<String, dynamic> archbaseSyncOperationToWire(ArchbaseSyncOperation op) {
  return {
    'id': op.id,
    'type': op.type,
    'aggregateId': op.aggregateId,
    'payload': op.payload,
    if (op.baseVersion != null) 'baseVersion': op.baseVersion,
    if (op.dependsOn != null) 'dependsOn': op.dependsOn,
    'clientCreatedAt': op.clientCreatedAt.toIso8601String(),
  };
}

/// Porta de envio do batch — abstrai o transporte HTTP para o motor ser testável
/// sem depender de um client concreto.
abstract interface class ArchbaseSyncSender {
  /// Envia o lote e devolve os ACKs. Deve lançar em falha de rede/transporte
  /// (o motor trata como "manter pendente", sem marcar erro de negócio).
  Future<ArchbaseSyncBatchResponse> send(
    List<ArchbaseSyncOperation> operations, {
    String? deviceId,
    bool atomic,
  });

  /// Reconciliação por transação: pergunta ao servidor quais dos [operationIds]
  /// já foram processados (estão no ledger). Read-only. Deve lançar em falha de
  /// rede/transporte (o motor trata como "tenta no próximo ciclo").
  Future<ArchbaseSyncStatusResponse> queryStatus(
    List<String> operationIds, {
    String? deviceId,
  });
}
