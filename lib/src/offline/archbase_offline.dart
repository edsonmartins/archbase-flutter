/// Módulo offline-first do Archbase (ADR-0001): store local + outbox + protocolo
/// batch. Ver `docs/design/archbase-offline-module.md`.
///
/// Coexiste com a `ArchbaseOfflineSyncQueue` legada (fila HTTP genérica sobre
/// Hive) durante a transição; esta é a fundação do motor definitivo.
library;

export 'archbase_syncable.dart';
export 'archbase_sync_operation.dart';
export 'archbase_sync_protocol.dart';
export 'archbase_local_store.dart';
export 'archbase_entity_codec.dart';
export 'archbase_sqflite_store.dart';
export 'archbase_binary_uploader.dart';
export 'archbase_sync_snapshot.dart';
export 'archbase_sync_engine.dart';
