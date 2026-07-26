/// Impl padrão do [ArchbaseLocalStore] sobre SQLite (`sqflite_common`).
///
/// Store genérico: entidades como JSON numa tabela única + a tabela de outbox.
/// A cifra fica a cargo do [opener] (o app abre via `sqflite_sqlcipher` com a
/// chave do secure storage; os testes usam `sqflite_common_ffi`). Reativo via
/// streams por tipo. Sem codegen, sem tabela por tipo — casa com o port genérico.
library;

import 'dart:async';
import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

import 'archbase_binary_uploader.dart';
import 'archbase_entity_codec.dart';
import 'archbase_local_store.dart';
import 'archbase_sync_operation.dart';
import 'archbase_syncable.dart';

class ArchbaseSqfliteStore implements ArchbaseLocalStore {
  ArchbaseSqfliteStore({
    required Future<Database> Function() opener,
    required ArchbaseEntityRegistry registry,
  })  : _opener = opener,
        _registry = registry;

  final Future<Database> Function() _opener;
  final ArchbaseEntityRegistry _registry;
  late final Database _db;
  bool _ready = false;

  final _events = <String, StreamController<void>>{};

  static const _tEntity = 'archbase_entity';
  static const _tOp = 'archbase_sync_operation';

  @override
  Future<void> initialize({String? encryptionKey}) async {
    if (_ready) return;
    _db = await _opener();
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS $_tEntity (
        type TEXT NOT NULL,
        id TEXT NOT NULL,
        data TEXT NOT NULL,
        sync_state TEXT NOT NULL,
        client_updated_at INTEGER,
        server_version INTEGER,
        deleted_at INTEGER,
        PRIMARY KEY (type, id)
      )''');
    await _db.execute(
        'CREATE INDEX IF NOT EXISTS idx_entity_type ON $_tEntity(type)');
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS $_tOp (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        aggregate_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        base_version INTEGER,
        depends_on TEXT,
        client_created_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        attempts INTEGER NOT NULL,
        next_retry_at INTEGER,
        last_error TEXT,
        processed_at INTEGER,
        ack_response TEXT,
        binaries TEXT
      )''');
    await _db
        .execute('CREATE INDEX IF NOT EXISTS idx_op_status ON $_tOp(status)');
    _ready = true;
  }

  StreamController<void> _eventsFor(String typeName) =>
      _events.putIfAbsent(typeName, () => StreamController<void>.broadcast());

  // --- Entidades ---

  @override
  Future<void> upsert<T extends ArchbaseSyncable>(T model) async {
    final codec = _registry.codecForRuntime(model);
    await _db.insert(
      _tEntity,
      {
        'type': codec.typeName,
        'id': model.id,
        'data': jsonEncode(codec.encode(model)),
        'sync_state': model.syncState.name,
        'client_updated_at': model.clientUpdatedAt.millisecondsSinceEpoch,
        'server_version': model.serverVersion,
        'deleted_at': model.deletedAt?.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _eventsFor(codec.typeName).add(null);
  }

  @override
  Future<T?> getById<T extends ArchbaseSyncable>(String id) async {
    final codec = _registry.codecOf<T>();
    final rows = await _db.query(_tEntity,
        where: 'type = ? AND id = ?',
        whereArgs: [codec.typeName, id],
        limit: 1);
    if (rows.isEmpty) return null;
    return codec.fromJson(_decode(rows.first['data'] as String));
  }

  @override
  Future<List<T>> query<T extends ArchbaseSyncable>([ArchbaseQuery? q]) async {
    final codec = _registry.codecOf<T>();
    final rows = await _db
        .query(_tEntity, where: 'type = ?', whereArgs: [codec.typeName]);
    final where = q?.where;
    final out = <T>[];
    for (final row in rows) {
      final json = _decode(row['data'] as String);
      if (where != null && !_matches(json, where)) continue;
      out.add(codec.fromJson(json));
      if (q?.limit != null && out.length >= q!.limit!) break;
    }
    return out;
  }

  @override
  Stream<List<T>> watch<T extends ArchbaseSyncable>([ArchbaseQuery? q]) {
    final typeName = _registry.typeNameOf<T>();
    late final StreamController<List<T>> ctrl;
    StreamSubscription<void>? sub;
    ctrl = StreamController<List<T>>(
      onListen: () {
        // Assina os eventos ANTES do emit inicial para não perder alterações.
        sub = _eventsFor(typeName)
            .stream
            .asyncMap((_) => query<T>(q))
            .listen(ctrl.add, onError: ctrl.addError);
        query<T>(q).then(ctrl.add).catchError(ctrl.addError);
      },
      onCancel: () => sub?.cancel(),
    );
    return ctrl.stream;
  }

  @override
  Future<void> deleteLocal<T extends ArchbaseSyncable>(String id) async {
    final codec = _registry.codecOf<T>();
    await _db.delete(_tEntity,
        where: 'type = ? AND id = ?', whereArgs: [codec.typeName, id]);
    _eventsFor(codec.typeName).add(null);
  }

  bool _matches(Map<String, dynamic> json, Map<String, Object?> where) {
    for (final e in where.entries) {
      if (json[e.key] != e.value) return false;
    }
    return true;
  }

  Map<String, dynamic> _decode(String s) =>
      (jsonDecode(s) as Map).cast<String, dynamic>();

  // --- Outbox ---

  @override
  Future<void> enqueue(ArchbaseSyncOperation op) async {
    await _db.insert(_tOp, _opToRow(op),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> updateOperation(ArchbaseSyncOperation op) async {
    await _db.insert(_tOp, _opToRow(op),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeOperation(String id) async {
    await _db.delete(_tOp, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<ArchbaseSyncOperation?> getOperation(String id) async {
    final rows =
        await _db.query(_tOp, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _rowToOp(rows.first);
  }

  @override
  Future<List<ArchbaseSyncOperation>> openOperations() async {
    final rows =
        await _db.query(_tOp, where: 'status IN (?, ?, ?, ?)', whereArgs: [
      ArchbaseSyncOpStatus.pending.name,
      ArchbaseSyncOpStatus.sending.name,
      ArchbaseSyncOpStatus.failed.name,
      ArchbaseSyncOpStatus.blocked.name,
    ]);
    return rows.map(_rowToOp).toList();
  }

  @override
  Future<List<ArchbaseSyncOperation>> operationsByStatus(
      ArchbaseSyncOpStatus status) async {
    final rows =
        await _db.query(_tOp, where: 'status = ?', whereArgs: [status.name]);
    return rows.map(_rowToOp).toList();
  }

  Map<String, Object?> _opToRow(ArchbaseSyncOperation op) => {
        'id': op.id,
        'type': op.type,
        'aggregate_id': op.aggregateId,
        'payload': jsonEncode(op.payload),
        'base_version': op.baseVersion,
        'depends_on': op.dependsOn,
        'client_created_at': op.clientCreatedAt.millisecondsSinceEpoch,
        'status': op.status.name,
        'attempts': op.attempts,
        'next_retry_at': op.nextRetryAt?.millisecondsSinceEpoch,
        'last_error': op.lastError,
        'processed_at': op.processedAt?.millisecondsSinceEpoch,
        'ack_response':
            op.ackResponse == null ? null : jsonEncode(op.ackResponse),
        'binaries': jsonEncode(op.binaries.map((b) => b.toJson()).toList()),
      };

  ArchbaseSyncOperation _rowToOp(Map<String, Object?> r) {
    DateTime? ms(Object? v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
    final binsRaw = r['binaries'] as String?;
    final bins = (binsRaw == null || binsRaw.isEmpty)
        ? const <ArchbaseOpBinary>[]
        : (jsonDecode(binsRaw) as List)
            .cast<Map>()
            .map((m) => ArchbaseOpBinary.fromJson(m.cast<String, dynamic>()))
            .toList();
    return ArchbaseSyncOperation(
      id: r['id'] as String,
      type: r['type'] as String,
      aggregateId: r['aggregate_id'] as String,
      payload: _decode(r['payload'] as String),
      clientCreatedAt: ms(r['client_created_at'])!,
      baseVersion: r['base_version'] as int?,
      dependsOn: r['depends_on'] as String?,
      status: ArchbaseSyncOpStatus.values.byName(r['status'] as String),
      attempts: r['attempts'] as int,
      nextRetryAt: ms(r['next_retry_at']),
      lastError: r['last_error'] as String?,
      processedAt: ms(r['processed_at']),
      ackResponse: (r['ack_response'] as String?) == null
          ? null
          : _decode(r['ack_response'] as String),
      binaries: bins,
    );
  }

  Future<void> close() async {
    for (final c in _events.values) {
      await c.close();
    }
    await _db.close();
  }
}
