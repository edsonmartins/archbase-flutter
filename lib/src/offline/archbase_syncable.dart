/// Contrato de modelo sincronizável do módulo `archbase_offline`.
///
/// Todo modelo de domínio que participa do offline-first implementa esta
/// interface. O motor ([ArchbaseSyncEngine]) e o store local
/// ([ArchbaseLocalStore]) operam sobre ela — sem conhecer "Visita"/"Pedido".
library;

/// Estado local de sincronização de uma entidade (por-entidade).
///
/// Nomeado `ArchbaseSyncState` para não colidir com o `ArchbaseSyncStatus`
/// legado (agregado da fila HTTP genérica). Serializado sempre por [name].
enum ArchbaseSyncState {
  /// Em edição; ainda não deve sincronizar.
  rascunho,

  /// Pronto para drenar (há operação na fila).
  pendente,

  /// Operação em voo (batch em andamento).
  enviando,

  /// ACK de sucesso e binários já enviados (gating cumprido).
  sincronizado,

  /// Estado terminal que exige ação (conflito, rejeição ou esgotamento).
  erro;

  /// Estados que representam trabalho ainda não confirmado pelo servidor.
  bool get isBacklog =>
      this == ArchbaseSyncState.pendente || this == ArchbaseSyncState.enviando;
}

/// Interface que um modelo de domínio precisa satisfazer para sincronizar.
abstract interface class ArchbaseSyncable {
  /// UUID gerado no cliente (CC1). Identidade e base da idempotência.
  String get id;

  /// Estado local de sincronização.
  ArchbaseSyncState get syncState;

  /// Relógio lógico do cliente (última escrita local) — usado no LWW.
  DateTime get clientUpdatedAt;

  /// Versão otimista conhecida do servidor (null = ainda não confirmado).
  int? get serverVersion;

  /// Soft delete: marcado localmente, propagado ao servidor.
  DateTime? get deletedAt;
}
