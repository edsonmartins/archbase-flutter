/// Motor offline-first do módulo `archbase_offline`.
///
/// Responsável pelo ciclo do outbox: enfileirar (escrita otimista), drenar em
/// batch, reconciliar por ACK, backoff, dead-letter, dependências, gating de
/// binário e crash-recovery. Não conhece o domínio — opera sobre
/// [ArchbaseSyncable]/[ArchbaseSyncOperation] e delega a atualização da entidade
/// ao app via [reconcile].
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'archbase_binary_uploader.dart';
import 'archbase_local_store.dart';
import 'archbase_sync_operation.dart';
import 'archbase_sync_protocol.dart';
import 'archbase_sync_snapshot.dart';
import 'archbase_syncable.dart';

/// Contexto entregue ao app para atualizar a entidade após um ACK/retry.
class ArchbaseReconcile {
  const ArchbaseReconcile({
    required this.operation,
    required this.entityState,
    this.ack,
    this.serverVersion,
    this.conflict,
  });

  final ArchbaseSyncOperation operation;

  /// Estado que a entidade de domínio deve assumir (o app aplica via copyWith).
  final ArchbaseSyncState entityState;

  final ArchbaseSyncAck? ack;
  final int? serverVersion;
  final Map<String, dynamic>? conflict;

  String get aggregateId => operation.aggregateId;
}

/// Resultado agregado de um [ArchbaseSyncEngine.drain].
class ArchbaseDrainResult {
  const ArchbaseDrainResult({
    this.sent = 0,
    this.processed = 0,
    this.skipped = 0,
    this.conflict = 0,
    this.failed = 0,
    this.blocked = 0,
    this.rejected = 0,
    this.exhausted = 0,
    this.networkError = false,
  });

  final int sent;
  final int processed;
  final int skipped;
  final int conflict;
  final int failed;
  final int blocked;
  final int rejected;
  final int exhausted;
  final bool networkError;
}

typedef ArchbaseReconcileHook = Future<void> Function(ArchbaseReconcile r);

class ArchbaseSyncEngine {
  ArchbaseSyncEngine({
    required ArchbaseLocalStore store,
    required ArchbaseSyncSender sender,
    required ArchbaseReconcileHook reconcile,
    ArchbaseBinaryUploader? binaryUploader,
    this.deviceId,
    this.batchSize = 50,
    this.maxAttempts = 5,
    this.backoffBase = const Duration(seconds: 2),
    DateTime Function()? clock,
    double Function(int attempt)? jitter,
    Uuid? uuid,
  })  : _store = store,
        _sender = sender,
        _reconcile = reconcile,
        _uploader = binaryUploader,
        _clock = clock ?? DateTime.now,
        _jitter = jitter ?? _defaultJitter,
        _uuid = uuid ?? const Uuid();

  final ArchbaseLocalStore _store;
  final ArchbaseSyncSender _sender;
  final ArchbaseReconcileHook _reconcile;
  final ArchbaseBinaryUploader? _uploader;
  final DateTime Function() _clock;
  final double Function(int attempt) _jitter;
  final Uuid _uuid;

  final String? deviceId;
  final int batchSize;
  final int maxAttempts;
  final Duration backoffBase;

  final ValueNotifier<ArchbaseSyncSnapshot> _snapshot =
      ValueNotifier<ArchbaseSyncSnapshot>(const ArchbaseSyncSnapshot());
  ValueListenable<ArchbaseSyncSnapshot> get snapshot => _snapshot;

  Completer<ArchbaseDrainResult>? _draining;

  static double _defaultJitter(int attempt) =>
      1.0 + (math.Random().nextDouble() * 0.2); // +0..20%

  // ---------------------------------------------------------------------------
  // Escrita otimista
  // ---------------------------------------------------------------------------

  /// Grava a entidade localmente (o app já a entregou com `syncState=pendente`)
  /// e enfileira a operação. Idempotente por [operationId]: reenfileirar o mesmo
  /// id não duplica.
  Future<ArchbaseSyncOperation> save({
    required ArchbaseSyncable model,
    required String type,
    required Map<String, dynamic> payload,
    String? operationId,
    String? dependsOn,
    List<ArchbaseOpBinary> binaries = const [],
    bool supersedeAggregate = false,
  }) async {
    await _store.upsert(model);

    final id = operationId ?? _uuid.v4();

    // Opt-in "delete vence upsert" (evita ghost record): antes de enfileirar esta
    // op, cancela QUALQUER outra op ainda no outbox do MESMO agregado — pending,
    // sending, blocked ou terminal. Sem isto, um DELETE convive com um UPSERT do
    // mesmo id e o upsert, drenado DEPOIS (ex.: blocked que desbloqueia, ou
    // esgotado que é reenviado), RECRIA o registro apagado. Default (false)
    // preserva o comportamento atual — nada muda para quem não opta.
    if (supersedeAggregate) {
      await _cancelOperationsForAggregate(model.id, except: id);
    }

    final existing = await _store.getOperation(id);
    if (existing == null) {
      final op = ArchbaseSyncOperation(
        id: id,
        type: type,
        aggregateId: model.id,
        payload: payload,
        clientCreatedAt: _clock(),
        baseVersion: model.serverVersion,
        dependsOn: dependsOn,
        binaries: binaries,
      );
      await _store.enqueue(op);
    }
    await _refreshSnapshot();
    return (await _store.getOperation(id))!;
  }

  /// Remove do outbox todas as operações do agregado [aggregateId], em QUALQUER
  /// estado (abertas + terminais), exceto a de id [except]. É a primitiva por trás
  /// do `supersedeAggregate` do [save] — o DELETE cancela um UPSERT concorrente do
  /// mesmo id para não ressuscitar o registro. Retorna quantas cancelou.
  Future<int> _cancelOperationsForAggregate(String aggregateId,
      {String? except}) async {
    final all = <ArchbaseSyncOperation>[
      ...await _store.openOperations(),
      ...await _store.operationsByStatus(ArchbaseSyncOpStatus.exhausted),
      ...await _store.operationsByStatus(ArchbaseSyncOpStatus.rejected),
      ...await _store.operationsByStatus(ArchbaseSyncOpStatus.conflict),
    ];
    var canceled = 0;
    for (final op in all) {
      if (op.aggregateId != aggregateId || op.id == except) continue;
      await _store.removeOperation(op.id);
      canceled++;
    }
    return canceled;
  }

  // ---------------------------------------------------------------------------
  // Drain
  // ---------------------------------------------------------------------------

  /// Drena a fila: recover → seleciona prontos (respeitando dependências e
  /// backoff) → envia em batch → reconcilia por ACK. Um drain por vez.
  Future<ArchbaseDrainResult> drain() {
    final inflight = _draining;
    if (inflight != null) return inflight.future;
    final completer = Completer<ArchbaseDrainResult>();
    _draining = completer;
    _runDrain().then((r) {
      _draining = null;
      completer.complete(r);
    }).catchError((Object e, StackTrace s) {
      _draining = null;
      _snapshot.value =
          _snapshot.value.copyWith(isSyncing: false, lastError: e.toString());
      completer.complete(const ArchbaseDrainResult(networkError: true));
    });
    return completer.future;
  }

  Future<ArchbaseDrainResult> _runDrain() async {
    await recoverStuck();
    _snapshot.value = _snapshot.value.copyWith(isSyncing: true, progress: 0.0);

    final open = await _store.openOperations();
    final now = _clock();

    // Índice de "concluídas" para resolver dependências (processed/skipped).
    // Uma dependência ausente do store é considerada satisfeita (já removida).
    final openById = {for (final o in open) o.id: o};

    Future<bool> depSatisfied(String? depId) async {
      if (depId == null) return true;
      final inOpen = openById[depId];
      if (inOpen != null) return inOpen.status.isDoneOk;
      final stored = await _store.getOperation(depId);
      if (stored == null) return true; // já processada e removida
      return stored.status.isDoneOk;
    }

    // Elegíveis: pending/failed(pronto por backoff). blocked reavalia.
    final eligible = <ArchbaseSyncOperation>[];
    for (final op in open) {
      if (op.status == ArchbaseSyncOpStatus.failed) {
        if (op.nextRetryAt != null && op.nextRetryAt!.isAfter(now)) continue;
      } else if (op.status != ArchbaseSyncOpStatus.pending &&
          op.status != ArchbaseSyncOpStatus.blocked) {
        continue;
      }
      eligible.add(op);
    }
    eligible.sort((a, b) => a.clientCreatedAt.compareTo(b.clientCreatedAt));

    final sendable = <ArchbaseSyncOperation>[];
    var blockedCount = 0;
    for (final op in eligible) {
      if (await depSatisfied(op.dependsOn)) {
        sendable.add(op);
      } else {
        if (op.status != ArchbaseSyncOpStatus.blocked) {
          await _store.updateOperation(
              op.copyWith(status: ArchbaseSyncOpStatus.blocked));
        }
        blockedCount++;
      }
      if (sendable.length >= batchSize) break;
    }

    if (sendable.isEmpty) {
      await _refreshSnapshot(isSyncing: false, progress: 1.0);
      return ArchbaseDrainResult(blocked: blockedCount);
    }

    // Marca sending (crash-recovery devolve a pending se cair aqui).
    for (final op in sendable) {
      await _store
          .updateOperation(op.copyWith(status: ArchbaseSyncOpStatus.sending));
    }
    await _refreshSnapshot(isSyncing: true, progress: 0.1);

    late final ArchbaseSyncBatchResponse resp;
    try {
      resp = await _sender.send(sendable, deviceId: deviceId, atomic: false);
    } catch (e) {
      // Falha de transporte: reverte para pending, mantém tudo. Sem erro de
      // negócio. Reprocessa no próximo ciclo.
      for (final op in sendable) {
        await _store
            .updateOperation(op.copyWith(status: ArchbaseSyncOpStatus.pending));
      }
      await _refreshSnapshot(isSyncing: false, lastError: e.toString());
      return const ArchbaseDrainResult(networkError: true);
    }

    final acks = {for (final a in resp.acks) a.id: a};
    var processed = 0, skipped = 0, conflict = 0, failed = 0;
    var rejected = 0, exhausted = 0, blockedAck = 0;

    for (final op in sendable) {
      final ack = acks[op.id];
      if (ack == null) {
        // Sem ACK: trata como transitório → volta a pending.
        await _store
            .updateOperation(op.copyWith(status: ArchbaseSyncOpStatus.pending));
        failed++;
        continue;
      }
      switch (ack.status) {
        case ArchbaseSyncOpStatus.processed:
        case ArchbaseSyncOpStatus.skipped:
          final gated = await _resolveBinariesAndReconcile(op, ack);
          if (gated) {
            (ack.status == ArchbaseSyncOpStatus.skipped)
                ? skipped++
                : processed++;
          } else {
            processed++; // permanece pendente por binário — reavalia depois
          }
          break;
        case ArchbaseSyncOpStatus.conflict:
          await _store.updateOperation(op.copyWith(
              status: ArchbaseSyncOpStatus.conflict,
              ackResponse: ack.conflict,
              processedAt: _clock()));
          await _reconcile(ArchbaseReconcile(
              operation: op,
              entityState: ArchbaseSyncState.erro,
              ack: ack,
              conflict: ack.conflict,
              serverVersion: ack.serverVersion));
          conflict++;
          break;
        case ArchbaseSyncOpStatus.rejected:
          await _store.updateOperation(op.copyWith(
              status: ArchbaseSyncOpStatus.rejected,
              lastError: ack.error,
              processedAt: _clock()));
          await _reconcile(ArchbaseReconcile(
              operation: op, entityState: ArchbaseSyncState.erro, ack: ack));
          rejected++;
          break;
        case ArchbaseSyncOpStatus.blocked:
          await _store.updateOperation(
              op.copyWith(status: ArchbaseSyncOpStatus.blocked));
          blockedAck++;
          break;
        case ArchbaseSyncOpStatus.failed:
        default:
          final attempts = op.attempts + 1;
          if (attempts >= maxAttempts) {
            await _store.updateOperation(op.copyWith(
                status: ArchbaseSyncOpStatus.exhausted,
                attempts: attempts,
                lastError: ack.error));
            await _reconcile(ArchbaseReconcile(
                operation: op, entityState: ArchbaseSyncState.erro, ack: ack));
            exhausted++;
          } else {
            await _store.updateOperation(op.copyWith(
                status: ArchbaseSyncOpStatus.failed,
                attempts: attempts,
                lastError: ack.error,
                nextRetryAt: _nextRetry(attempts)));
            await _reconcile(ArchbaseReconcile(
                operation: op,
                entityState: ArchbaseSyncState.pendente,
                ack: ack));
            failed++;
          }
          break;
      }
    }

    await _refreshSnapshot(isSyncing: false, progress: 1.0);
    return ArchbaseDrainResult(
      sent: sendable.length,
      processed: processed,
      skipped: skipped,
      conflict: conflict,
      failed: failed,
      blocked: blockedCount + blockedAck,
      rejected: rejected,
      exhausted: exhausted,
    );
  }

  /// Sobe binários pendentes da op; reconcilia a entidade. Retorna `true` se a
  /// entidade fechou (`sincronizado`) — `false` se ficou pendente por binário.
  Future<bool> _resolveBinariesAndReconcile(
      ArchbaseSyncOperation op, ArchbaseSyncAck ack) async {
    if (op.binaries.isEmpty || !op.hasPendingBinaries) {
      await _reconcile(ArchbaseReconcile(
          operation: op,
          entityState: ArchbaseSyncState.sincronizado,
          ack: ack,
          serverVersion: ack.serverVersion));
      await _store.removeOperation(op.id);
      return true;
    }

    final uploader = _uploader;
    var updated = op.binaries;
    var allOk = true;
    if (uploader != null) {
      final next = <ArchbaseOpBinary>[];
      for (final b in updated) {
        if (b.isUploaded) {
          next.add(b);
          continue;
        }
        try {
          final r = await uploader.upload(
              localPath: b.localPath, category: b.category, meta: b.meta);
          next.add(b.copyWith(remoteId: r.remoteId));
        } catch (_) {
          next.add(b);
          allOk = false;
        }
      }
      updated = next;
    } else {
      allOk = false;
    }

    if (allOk) {
      await _reconcile(ArchbaseReconcile(
          operation: op,
          entityState: ArchbaseSyncState.sincronizado,
          ack: ack,
          serverVersion: ack.serverVersion));
      await _store.removeOperation(op.id);
      return true;
    } else {
      // JSON aceito, binário pendente: entidade permanece pendente (gating).
      // Op volta a pending para reenvio; o servidor deduplica (skipped) e os
      // binários são retentados no próximo ciclo.
      await _store.updateOperation(op.copyWith(
          status: ArchbaseSyncOpStatus.pending,
          binaries: updated,
          processedAt: _clock()));
      await _reconcile(ArchbaseReconcile(
          operation: op,
          entityState: ArchbaseSyncState.pendente,
          ack: ack,
          serverVersion: ack.serverVersion));
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Recovery / retry
  // ---------------------------------------------------------------------------

  /// Devolve operações órfãs em `sending` (crash) para `pending`.
  Future<void> recoverStuck() async {
    final stuck = await _store.operationsByStatus(ArchbaseSyncOpStatus.sending);
    for (final op in stuck) {
      await _store.updateOperation(op.copyWith(
          status: ArchbaseSyncOpStatus.pending, clearNextRetryAt: true));
    }
  }

  /// Reenvio manual de uma operação em erro terminal (conflict/exhausted/
  /// rejected) ou failed: volta a `pending`, zera tentativas e devolve a
  /// entidade a `pendente`.
  Future<void> retry(String operationId) async {
    final op = await _store.getOperation(operationId);
    if (op == null) return;
    final reset = op.copyWith(
      status: ArchbaseSyncOpStatus.pending,
      attempts: 0,
      clearNextRetryAt: true,
      clearLastError: true,
    );
    await _store.updateOperation(reset);
    await _reconcile(ArchbaseReconcile(
        operation: reset, entityState: ArchbaseSyncState.pendente));
    await _refreshSnapshot();
  }

  /// Operações em erro TERMINAL (conflict/exhausted/rejected) — para o app
  /// listar com o motivo ([ArchbaseSyncOperation.lastError]) e oferecer ação.
  Future<List<ArchbaseSyncOperation>> failedOperations() async {
    final result = <ArchbaseSyncOperation>[];
    for (final s in const [
      ArchbaseSyncOpStatus.rejected,
      ArchbaseSyncOpStatus.exhausted,
      ArchbaseSyncOpStatus.conflict,
    ]) {
      result.addAll(await _store.operationsByStatus(s));
    }
    return result;
  }

  /// Reconciliação por transação (o "já processou?"): para as operações ainda
  /// não confirmadas localmente (pending/sending/failed/blocked/exhausted),
  /// pergunta ao servidor quais já foram processadas e fecha essas — marca a
  /// entidade `sincronizado` e remove a op. Resolve o caso "o servidor deu
  /// commit mas o cliente perdeu o response" (inclusive as que esgotaram o retry).
  ///
  /// Read-only no servidor (não reexecuta a mutação). Tolerante a falha de rede:
  /// devolve 0 e tenta de novo no próximo ciclo. Retorna quantas foram fechadas.
  Future<int> reconcilePendentes() async {
    final candidatas = <ArchbaseSyncOperation>[
      ...await _store.openOperations(), // pending/sending/failed/blocked
      ...await _store.operationsByStatus(ArchbaseSyncOpStatus.exhausted),
    ];
    if (candidatas.isEmpty) return 0;

    final ids = candidatas.map((o) => o.id).toList();
    final ArchbaseSyncStatusResponse resp;
    try {
      resp = await _sender.queryStatus(ids, deviceId: deviceId);
    } catch (_) {
      return 0; // falha de rede → tenta no próximo ciclo
    }

    final processadas = resp.processed.toSet();
    var fechadas = 0;
    for (final op in candidatas) {
      if (!processadas.contains(op.id)) continue;
      await _reconcile(ArchbaseReconcile(
          operation: op, entityState: ArchbaseSyncState.sincronizado));
      await _store.removeOperation(op.id);
      fechadas++;
    }
    if (fechadas > 0) await _refreshSnapshot();
    return fechadas;
  }

  // ---------------------------------------------------------------------------
  // Snapshot
  // ---------------------------------------------------------------------------

  DateTime _nextRetry(int attempts) {
    final expo = backoffBase.inMilliseconds *
        math.pow(2, math.min(attempts - 1, 6)).toInt();
    final ms = (expo * _jitter(attempts)).round();
    return _clock().add(Duration(milliseconds: ms));
  }

  Future<void> _refreshSnapshot({
    bool? isSyncing,
    double? progress,
    String? lastError,
  }) async {
    Future<int> count(ArchbaseSyncOpStatus s) async =>
        (await _store.operationsByStatus(s)).length;
    final pending = await count(ArchbaseSyncOpStatus.pending);
    final sending = await count(ArchbaseSyncOpStatus.sending);
    final failed = await count(ArchbaseSyncOpStatus.failed);
    final conflict = await count(ArchbaseSyncOpStatus.conflict);
    final exhausted = await count(ArchbaseSyncOpStatus.exhausted);
    final blocked = await count(ArchbaseSyncOpStatus.blocked);
    _snapshot.value = _snapshot.value.copyWith(
      isSyncing: isSyncing,
      pending: pending,
      sending: sending,
      failed: failed,
      conflict: conflict,
      exhausted: exhausted,
      blocked: blocked,
      progress: progress,
      lastSyncAt: (isSyncing == false) ? _clock() : null,
      lastError: lastError,
    );
  }

  void dispose() => _snapshot.dispose();
}
