import 'package:archbase_flutter/src/offline/archbase_offline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Pedido implements ArchbaseSyncable {
  _Pedido(this.id,
      {this.syncState = ArchbaseSyncState.pendente,
      DateTime? clientUpdatedAt,
      this.serverVersion,
      this.deletedAt,
      this.pdvId = 'pdv1'})
      : clientUpdatedAt = clientUpdatedAt ?? DateTime(2026, 1, 1);

  @override
  final String id;
  @override
  final ArchbaseSyncState syncState;
  @override
  final DateTime clientUpdatedAt;
  @override
  final int? serverVersion;
  @override
  final DateTime? deletedAt;
  final String pdvId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'syncState': syncState.name,
        'clientUpdatedAt': clientUpdatedAt.toIso8601String(),
        'serverVersion': serverVersion,
        'deletedAt': deletedAt?.toIso8601String(),
        'pdvId': pdvId,
      };

  factory _Pedido.fromJson(Map<String, dynamic> j) => _Pedido(
        j['id'] as String,
        syncState: ArchbaseSyncState.values.byName(j['syncState'] as String),
        clientUpdatedAt: DateTime.parse(j['clientUpdatedAt'] as String),
        serverVersion: j['serverVersion'] as int?,
        deletedAt: j['deletedAt'] == null
            ? null
            : DateTime.parse(j['deletedAt'] as String),
        pdvId: j['pdvId'] as String? ?? 'pdv1',
      );
}

void main() {
  sqfliteFfiInit();

  ArchbaseEntityRegistry buildRegistry() {
    final r = ArchbaseEntityRegistry();
    r.register<_Pedido>(ArchbaseEntityCodec<_Pedido>(
      typeName: 'Pedido',
      fromJson: _Pedido.fromJson,
      toJson: (p) => p.toJson(),
    ));
    return r;
  }

  Future<ArchbaseSqfliteStore> openStore() async {
    final store = ArchbaseSqfliteStore(
      opener: () => databaseFactoryFfi.openDatabase(inMemoryDatabasePath),
      registry: buildRegistry(),
    );
    await store.initialize();
    return store;
  }

  group('ArchbaseSqfliteStore', () {
    test('round-trip de entidade + query por campo', () async {
      final store = await openStore();
      await store.upsert(_Pedido('p1', pdvId: 'A'));
      await store.upsert(_Pedido('p2', pdvId: 'B'));

      final byId = await store.getById<_Pedido>('p1');
      expect(byId, isNotNull);
      expect(byId!.pdvId, 'A');

      final all = await store.query<_Pedido>();
      expect(all.length, 2);

      final filtered = await store
          .query<_Pedido>(const ArchbaseQuery(where: {'pdvId': 'B'}));
      expect(filtered.map((e) => e.id), ['p2']);
      await store.close();
    });

    test('watch emite estado inicial e reage a alteração', () async {
      final store = await openStore();
      final stream = store.watch<_Pedido>();
      final firstOne = stream.firstWhere((l) => l.length == 1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await store.upsert(_Pedido('p1'));
      final l = await firstOne.timeout(const Duration(seconds: 2));
      expect(l.single.id, 'p1');
      await store.close();
    });

    test('outbox: enqueue/get/update/status/remove persistem', () async {
      final store = await openStore();
      final op = ArchbaseSyncOperation(
        id: 'op1',
        type: 'PEDIDO_UPSERT',
        aggregateId: 'p1',
        payload: const {'x': 1},
        clientCreatedAt: DateTime(2026, 1, 1),
        binaries: const [
          ArchbaseOpBinary(localPath: '/f.jpg', category: 'FOTO')
        ],
      );
      await store.enqueue(op);

      final got = await store.getOperation('op1');
      expect(got, isNotNull);
      expect(got!.type, 'PEDIDO_UPSERT');
      expect(got.payload['x'], 1);
      expect(got.binaries.single.category, 'FOTO');
      expect(got.status, ArchbaseSyncOpStatus.pending);

      await store
          .updateOperation(got.copyWith(status: ArchbaseSyncOpStatus.sending));
      expect(
          (await store.operationsByStatus(ArchbaseSyncOpStatus.sending)).length,
          1);
      expect((await store.openOperations()).length, 1);

      await store.removeOperation('op1');
      expect(await store.getOperation('op1'), isNull);
      await store.close();
    });

    test('motor completo sobre o store real: save→drain→sincronizado',
        () async {
      final store = await openStore();
      final sender = _AckAllSender();
      final engine = ArchbaseSyncEngine(
        store: store,
        sender: sender,
        reconcile: (r) async {
          final m = await store.getById<_Pedido>(r.aggregateId);
          if (m == null) return;
          await store.upsert(_Pedido(m.id,
              syncState: r.entityState,
              serverVersion: r.serverVersion ?? m.serverVersion,
              pdvId: m.pdvId));
        },
      );

      await engine.save(
          model: _Pedido('p1'),
          type: 'PEDIDO_UPSERT',
          payload: const {'x': 1},
          operationId: 'op1');
      expect((await store.openOperations()).length, 1);

      await engine.drain();
      expect(await store.getOperation('op1'), isNull);
      expect((await store.getById<_Pedido>('p1'))!.syncState,
          ArchbaseSyncState.sincronizado);
      engine.dispose();
      await store.close();
    });
  });
}

class _AckAllSender implements ArchbaseSyncSender {
  @override
  Future<ArchbaseSyncBatchResponse> send(List<ArchbaseSyncOperation> operations,
      {String? deviceId, bool atomic = false}) async {
    return ArchbaseSyncBatchResponse(
      acks: operations
          .map((o) => ArchbaseSyncAck(
              id: o.id,
              status: ArchbaseSyncOpStatus.processed,
              serverVersion: 1))
          .toList(),
    );
  }
}
