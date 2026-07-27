import 'dart:async';

import 'package:archbase_flutter/src/offline/archbase_offline.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers de teste (fakes)
// ---------------------------------------------------------------------------

class _Model implements ArchbaseSyncable {
  _Model(
    this.id, {
    this.syncState = ArchbaseSyncState.pendente,
    DateTime? clientUpdatedAt,
    this.serverVersion,
    this.deletedAt,
  }) : clientUpdatedAt = clientUpdatedAt ?? DateTime(2026, 1, 1);

  @override
  final String id;
  @override
  ArchbaseSyncState syncState;
  @override
  DateTime clientUpdatedAt;
  @override
  int? serverVersion;
  @override
  DateTime? deletedAt;

  _Model copyWith({ArchbaseSyncState? syncState, int? serverVersion}) => _Model(
        id,
        syncState: syncState ?? this.syncState,
        clientUpdatedAt: clientUpdatedAt,
        serverVersion: serverVersion ?? this.serverVersion,
        deletedAt: deletedAt,
      );
}

/// Store em memória — a impl drift real virá depois; aqui prova a lógica do motor.
class _MemStore implements ArchbaseLocalStore {
  final Map<String, ArchbaseSyncable> _entities = {};
  final Map<String, ArchbaseSyncOperation> _ops = {};

  @override
  Future<void> initialize({String? encryptionKey}) async {}

  @override
  Future<T?> getById<T extends ArchbaseSyncable>(String id) async =>
      _entities[id] as T?;

  @override
  Future<List<T>> query<T extends ArchbaseSyncable>([ArchbaseQuery? q]) async =>
      _entities.values.whereType<T>().toList();

  @override
  Stream<List<T>> watch<T extends ArchbaseSyncable>([ArchbaseQuery? q]) =>
      Stream.value(_entities.values.whereType<T>().toList());

  @override
  Future<void> upsert<T extends ArchbaseSyncable>(T model) async {
    _entities[model.id] = model;
  }

  @override
  Future<void> deleteLocal<T extends ArchbaseSyncable>(String id) async {
    _entities.remove(id);
  }

  @override
  Future<void> enqueue(ArchbaseSyncOperation op) async => _ops[op.id] = op;

  @override
  Future<void> updateOperation(ArchbaseSyncOperation op) async =>
      _ops[op.id] = op;

  @override
  Future<void> removeOperation(String id) async => _ops.remove(id);

  @override
  Future<ArchbaseSyncOperation?> getOperation(String id) async => _ops[id];

  static const _open = {
    ArchbaseSyncOpStatus.pending,
    ArchbaseSyncOpStatus.sending,
    ArchbaseSyncOpStatus.failed,
    ArchbaseSyncOpStatus.blocked,
  };

  @override
  Future<List<ArchbaseSyncOperation>> openOperations() async =>
      _ops.values.where((o) => _open.contains(o.status)).toList();

  @override
  Future<List<ArchbaseSyncOperation>> operationsByStatus(
          ArchbaseSyncOpStatus status) async =>
      _ops.values.where((o) => o.status == status).toList();
}

typedef _Handler = List<ArchbaseSyncAck> Function(
    List<ArchbaseSyncOperation> ops);

class _FakeSender implements ArchbaseSyncSender {
  _FakeSender(this.handler);
  _Handler handler;
  bool throwNetwork = false;
  int sends = 0;

  @override
  Future<ArchbaseSyncBatchResponse> send(List<ArchbaseSyncOperation> operations,
      {String? deviceId, bool atomic = false}) async {
    sends++;
    if (throwNetwork) throw StateError('network down');
    return ArchbaseSyncBatchResponse(acks: handler(operations));
  }
}

class _FakeUploader implements ArchbaseBinaryUploader {
  bool ok = true;
  int uploads = 0;
  @override
  Future<ArchbaseBinaryUploadResult> upload(
      {required String localPath,
      required String category,
      Map<String, dynamic>? meta}) async {
    uploads++;
    if (!ok) throw StateError('upload failed');
    return ArchbaseBinaryUploadResult(remoteId: 'remote-$uploads');
  }
}

class _Clock {
  DateTime now = DateTime(2026, 1, 1, 12);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

ArchbaseSyncAck _ack(String id, ArchbaseSyncOpStatus status,
        {int? serverVersion, Map<String, dynamic>? conflict, String? error}) =>
    ArchbaseSyncAck(
        id: id,
        status: status,
        serverVersion: serverVersion,
        conflict: conflict,
        error: error);

/// Monta um motor com reconcile que aplica o estado na entidade do store.
({
  ArchbaseSyncEngine engine,
  _MemStore store,
  _FakeSender sender,
  _FakeUploader uploader,
  _Clock clock
}) _build(_Handler handler, {int maxAttempts = 5}) {
  final store = _MemStore();
  final sender = _FakeSender(handler);
  final uploader = _FakeUploader();
  final clock = _Clock();
  final engine = ArchbaseSyncEngine(
    store: store,
    sender: sender,
    binaryUploader: uploader,
    maxAttempts: maxAttempts,
    clock: clock.call,
    jitter: (_) => 1.0, // determinístico
    reconcile: (r) async {
      final m = store._entities[r.aggregateId] as _Model?;
      if (m == null) return;
      store._entities[r.aggregateId] = m.copyWith(
          syncState: r.entityState,
          serverVersion: r.serverVersion ?? m.serverVersion);
    },
  );
  return (
    engine: engine,
    store: store,
    sender: sender,
    uploader: uploader,
    clock: clock
  );
}

void main() {
  group('ArchbaseSyncEngine — gate', () {
    test('1. Idempotência: mesma operationId não duplica; skipped fecha',
        () async {
      final h = _build((ops) =>
          ops.map((o) => _ack(o.id, ArchbaseSyncOpStatus.skipped)).toList());
      await h.engine.save(
          model: _Model('v1'),
          type: 'T',
          payload: const {},
          operationId: 'op1');
      await h.engine.save(
          model: _Model('v1'),
          type: 'T',
          payload: const {},
          operationId: 'op1');
      expect((await h.store.openOperations()).length, 1,
          reason: 'não duplica por id');

      await h.engine.drain();
      expect(await h.store.getOperation('op1'), isNull,
          reason: 'skipped remove a op');
      expect((h.store._entities['v1'] as _Model).syncState,
          ArchbaseSyncState.sincronizado);
    });

    test('2. Conflito: não sobrescreve; entidade vai a erro', () async {
      final h = _build((ops) => [
            _ack(ops.first.id, ArchbaseSyncOpStatus.conflict,
                serverVersion: 9, conflict: {'serverVersion': 9})
          ]);
      await h.engine.save(
          model: _Model('v1', serverVersion: 3),
          type: 'T',
          payload: const {},
          operationId: 'op1');
      await h.engine.drain();
      final op = await h.store.getOperation('op1');
      expect(op!.status, ArchbaseSyncOpStatus.conflict);
      expect((h.store._entities['v1'] as _Model).syncState,
          ArchbaseSyncState.erro);
    });

    test('3. Erro parcial: um conflito não derruba os demais', () async {
      final h = _build((ops) => [
            _ack(ops[0].id, ArchbaseSyncOpStatus.processed, serverVersion: 2),
            _ack(ops[1].id, ArchbaseSyncOpStatus.conflict),
          ]);
      await h.engine.save(
          model: _Model('a'), type: 'T', payload: const {}, operationId: 'opA');
      await h.engine.save(
          model: _Model('b'), type: 'T', payload: const {}, operationId: 'opB');
      await h.engine.drain();
      expect(await h.store.getOperation('opA'), isNull);
      expect((h.store._entities['a'] as _Model).syncState,
          ArchbaseSyncState.sincronizado);
      expect((await h.store.getOperation('opB'))!.status,
          ArchbaseSyncOpStatus.conflict);
      expect(
          (h.store._entities['b'] as _Model).syncState, ArchbaseSyncState.erro);
    });

    test('4. Dependência: dependente fica blocked até a dependência concluir',
        () async {
      // 1ª rodada: só A é processada; B depende de A e ainda não foi enviada.
      final h = _build((ops) => ops
          .where((o) => o.id == 'opA')
          .map((o) => _ack(o.id, ArchbaseSyncOpStatus.processed))
          .toList());
      await h.engine.save(
          model: _Model('a'), type: 'T', payload: const {}, operationId: 'opA');
      await h.engine.save(
          model: _Model('b'),
          type: 'T',
          payload: const {},
          operationId: 'opB',
          dependsOn: 'opA');

      await h.engine.drain();
      expect(await h.store.getOperation('opA'), isNull, reason: 'A processada');
      expect((await h.store.getOperation('opB'))!.status,
          ArchbaseSyncOpStatus.blocked);

      // 2ª rodada: A já não existe (satisfeita) → B libera e processa.
      h.sender.handler = (ops) =>
          ops.map((o) => _ack(o.id, ArchbaseSyncOpStatus.processed)).toList();
      await h.engine.drain();
      expect(await h.store.getOperation('opB'), isNull);
      expect((h.store._entities['b'] as _Model).syncState,
          ArchbaseSyncState.sincronizado);
    });

    test('5. Dead-letter: esgota tentativas → exhausted; retry volta a pending',
        () async {
      final h = _build(
          (ops) =>
              [_ack(ops.first.id, ArchbaseSyncOpStatus.failed, error: 'x')],
          maxAttempts: 2);
      await h.engine.save(
          model: _Model('v1'),
          type: 'T',
          payload: const {},
          operationId: 'op1');

      await h.engine.drain(); // attempt 1 → failed
      expect((await h.store.getOperation('op1'))!.status,
          ArchbaseSyncOpStatus.failed);
      h.clock.advance(const Duration(minutes: 5)); // passa o backoff

      await h.engine.drain(); // attempt 2 → exhausted
      final op = await h.store.getOperation('op1');
      expect(op!.status, ArchbaseSyncOpStatus.exhausted);
      expect((h.store._entities['v1'] as _Model).syncState,
          ArchbaseSyncState.erro);

      await h.engine.retry('op1');
      final r = await h.store.getOperation('op1');
      expect(r!.status, ArchbaseSyncOpStatus.pending);
      expect(r.attempts, 0);
      expect((h.store._entities['v1'] as _Model).syncState,
          ArchbaseSyncState.pendente);
    });

    test('6. Crash-recovery: sending órfão volta a pending', () async {
      final h = _build((ops) => const []);
      await h.store.enqueue(ArchbaseSyncOperation(
        id: 'op1',
        type: 'T',
        aggregateId: 'v1',
        payload: const {},
        clientCreatedAt: h.clock(),
        status: ArchbaseSyncOpStatus.sending,
      ));
      await h.engine.recoverStuck();
      expect((await h.store.getOperation('op1'))!.status,
          ArchbaseSyncOpStatus.pending);
    });

    test(
        '7. Gating de binário: foto pendente mantém pendente; sobe → sincronizado',
        () async {
      final h = _build((ops) =>
          ops.map((o) => _ack(o.id, ArchbaseSyncOpStatus.processed)).toList());
      h.uploader.ok = false; // upload falha primeiro
      await h.engine.save(
        model: _Model('v1'),
        type: 'T',
        payload: const {},
        operationId: 'op1',
        binaries: const [
          ArchbaseOpBinary(localPath: '/tmp/f.jpg', category: 'FOTO')
        ],
      );

      await h.engine.drain(); // JSON aceito, binário falha → gating
      expect((h.store._entities['v1'] as _Model).syncState,
          ArchbaseSyncState.pendente,
          reason: 'não pode "mentir" sincronizado sem a foto');
      expect((await h.store.getOperation('op1'))!.status,
          ArchbaseSyncOpStatus.pending);

      h.uploader.ok = true; // agora a foto sobe
      await h.engine.drain();
      expect(await h.store.getOperation('op1'), isNull);
      expect((h.store._entities['v1'] as _Model).syncState,
          ArchbaseSyncState.sincronizado);
    });

    test('8. Enum serializado por nome (regressão .value/.name)', () {
      expect(ArchbaseSyncOpStatus.sending.name, 'sending');
      expect(ArchbaseSyncState.sincronizado.name, 'sincronizado');
    });

    test('rede fora: mantém pendente, sem marcar erro de negócio', () async {
      final h = _build((ops) =>
          ops.map((o) => _ack(o.id, ArchbaseSyncOpStatus.processed)).toList());
      await h.engine.save(
          model: _Model('v1'),
          type: 'T',
          payload: const {},
          operationId: 'op1');
      h.sender.throwNetwork = true;
      final r = await h.engine.drain();
      expect(r.networkError, isTrue);
      expect((await h.store.getOperation('op1'))!.status,
          ArchbaseSyncOpStatus.pending);
    });
  });
}
