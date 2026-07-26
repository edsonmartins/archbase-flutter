/// Porta do store local do módulo `archbase_offline`.
///
/// O motor fala esta porta, não o ORM. A impl padrão será drift (SQLite cifrado);
/// os testes usam uma impl em memória. Mantém o app livre e testável.
library;

import 'archbase_syncable.dart';
import 'archbase_sync_operation.dart';

/// Filtro simples de consulta local (subconjunto suficiente para o offline-first).
class ArchbaseQuery {
  const ArchbaseQuery({this.where, this.limit});

  /// Igualdades exatas por campo (AND). Ex.: `{'pdvId': 'x', 'deleted': false}`.
  final Map<String, Object?>? where;
  final int? limit;
}

/// Store local: entidades de domínio + outbox. Reativo via [watch].
abstract interface class ArchbaseLocalStore {
  Future<void> initialize({String? encryptionKey});

  // --- Entidades de domínio ---
  Future<T?> getById<T extends ArchbaseSyncable>(String id);
  Future<List<T>> query<T extends ArchbaseSyncable>([ArchbaseQuery? q]);
  Stream<List<T>> watch<T extends ArchbaseSyncable>([ArchbaseQuery? q]);

  /// Grava/atualiza localmente (sem enfileirar mutação REST).
  Future<void> upsert<T extends ArchbaseSyncable>(T model);

  /// Remove fisicamente do store local (raro — o normal é soft-delete no modelo).
  Future<void> deleteLocal<T extends ArchbaseSyncable>(String id);

  // --- Outbox ---
  Future<void> enqueue(ArchbaseSyncOperation op);
  Future<void> updateOperation(ArchbaseSyncOperation op);
  Future<void> removeOperation(String id);
  Future<ArchbaseSyncOperation?> getOperation(String id);

  /// Todas as operações não-terminais (pending/sending/failed/blocked).
  Future<List<ArchbaseSyncOperation>> openOperations();

  /// Operações num dado status (ex.: para crash-recovery de `sending`).
  Future<List<ArchbaseSyncOperation>> operationsByStatus(
      ArchbaseSyncOpStatus status);
}
