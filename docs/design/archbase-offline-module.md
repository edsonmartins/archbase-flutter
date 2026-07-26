# Contrato do módulo `archbase_offline`

> Companion do [ADR-0001](../adr/ADR-0001-motor-offline-first.md). Define o **contrato técnico** do motor offline-first do `archbase_flutter`: interfaces, modelo de dados, protocolo de rede, semântica e a fronteira lib × app. É a referência de implementação e de **revalidação**.

**Status:** Proposto · **Versão do contrato:** `1.0-draft` · **Data:** 2026-07-26

---

## 1. Princípios

1. **O aparelho é a fonte de verdade da UI.** Toda leitura/escrita da tela passa pelo store local. A rede é assíncrona.
2. **Escrita otimista.** A ação grava local na hora (`syncStatus = pendente`) e a tela reflete imediatamente; o envio vem depois.
3. **Uma superfície de sync.** Todas as mutações drenam por um **outbox** único via **batch** `POST /api/v1/sync/operations`. Sem PUT-por-recurso paralelo.
4. **Nada se perde nem duplica.** Idempotência durável por `id` de cliente; conflito e dead-letter tipados.
5. **A lib é genérica; o app é o domínio.** O motor não conhece "Visita" nem "Pedido".

---

## 2. Camadas e fronteira lib × app

```
┌────────────────────────────────────────────────────────────────┐
│ APP (vendax-promoter, rio-quality, ...)                         │
│  • Telas (CONGELADAS)                                            │
│  • Providers/estado (mantêm o contrato que a tela consome)      │
│  • Models de domínio  (implements ArchbaseSyncable)             │
│  • PayloadBuilders    (model → JSON do contrato do backend)     │
│  • Registro de tipos de operação + tabelas drift do domínio     │
└───────────────▲───────────────────────────┬────────────────────┘
                │ lê/escreve/observa         │ enfileira operação
┌───────────────┴───────────────────────────▼────────────────────┐
│ archbase_offline (LIB)                                          │
│  • ArchbaseSyncable            (contrato de modelo)             │
│  • ArchbaseLocalStore (port)   + impl drift (SQLCipher)         │
│  • ArchbaseOfflineRepository<T>(leitura local, escrita otimista,│
│                                 subscribe)                       │
│  • ArchbaseSyncEngine          (outbox + drain + reconciliação) │
│  • SyncOperation / SyncOpStatus / protocolo batch (DTOs)        │
│  • ArchbaseBinaryUploader (port)  (fotos/assinaturas multipart) │
│  • Widgets de feedback (badge/banner/contador)                  │
└───────────────▲────────────────────────────────────────────────┘
                │ HTTP (ArchbaseApiClient já existente)
┌───────────────┴────────────────────────────────────────────────┐
│ BACKEND (archbase-java-boilerplate → cada API)                 │
│  • POST /api/v1/sync/operations (batch + ACK)                   │
│  • SyncOperationProcessor (base) + SyncOperationHandler<T>      │
│  • processed_sync_operation (idempotência durável)             │
└────────────────────────────────────────────────────────────────┘
```

**Regra da costura no app:** o widget não muda. O provider continua expondo o **mesmo estado**; por baixo, ele passa a ler de `ArchbaseOfflineRepository` e a escrever via `repository.save(...)` (que grava local + enfileira). Onde o provider tem lógica pesada, ela é re-hospedada preservando a **saída idêntica** para a tela.

---

## 3. Contrato de modelo — `ArchbaseSyncable`

Todo modelo sincronizável do domínio implementa:

```dart
abstract interface class ArchbaseSyncable {
  /// UUID gerado no cliente (CC1). É a identidade e a base da idempotência.
  String get id;

  /// Estado local de sincronização.
  ArchbaseSyncStatus get syncStatus;

  /// Relógio lógico do cliente para LWW (última escrita local).
  DateTime get clientUpdatedAt;

  /// Versão otimista conhecida do servidor (null = ainda não confirmado).
  int? get serverVersion;

  /// Soft delete: marcado localmente, propagado ao servidor.
  DateTime? get deletedAt;

  /// Chave de idempotência da mutação corrente (reutilizada em retry).
  String? get idempotencyKey;
}
```

`ArchbaseSyncStatus`: `rascunho · pendente · enviando · sincronizado · erro`.
- `rascunho`: em edição, ainda não deve sincronizar.
- `pendente`: pronto para drenar (na fila).
- `enviando`: em voo (batch em andamento).
- `sincronizado`: ACK `PROCESSED` **e** binários enviados (gating).
- `erro`: ACK terminal `FAILED`/`CONFLICT`/`EXHAUSTED` → exige ação (reenvio manual / resolução).

> Serialização de enum **sempre por nome** (`.name`), nunca por índice — tanto no store quanto na query. (Bug real da Tentativa B: query por `'SENDING'` numa coluna que guardava `'sending'` → crash-recovery inerte.)

---

## 4. Store local — `ArchbaseLocalStore` (port) + impl drift

O motor não fala drift diretamente; fala a port. Isso mantém o app livre e testável (fake em memória).

```dart
abstract interface class ArchbaseLocalStore {
  Future<void> initialize({required String encryptionKey});

  Future<T?>       getById<T extends ArchbaseSyncable>(String id);
  Future<List<T>>  query<T extends ArchbaseSyncable>([ArchbaseQuery? q]);
  Stream<List<T>>  watch<T extends ArchbaseSyncable>([ArchbaseQuery? q]); // reativo

  Future<void> upsert<T extends ArchbaseSyncable>(T model);   // grava local (sem enfileirar)
  Future<void> delete<T extends ArchbaseSyncable>(String id); // hard delete local (raro)

  // Outbox (tabela própria do motor, ver §5)
  Future<void>                enqueue(SyncOperation op);
  Future<List<SyncOperation>> pendingOperations({int limit});
  Future<void>                updateOperation(SyncOperation op);
  Future<void>                removeOperation(String id);
}
```

**Impl padrão:** `DriftLocalStore` — SQLite via `sqflite_sqlcipher`/`drift`, chave no `flutter_secure_storage`. Tabelas do domínio são declaradas **no app** (drift `@DataClassName`), mais a tabela `sync_operation` que a lib registra. Streams do drift alimentam o `watch<T>` (reatividade nativa).

> **Decisão de ORM:** `drift` (ADR-0001 §2). Reativo, tipado, sem camada de sync opinativa. O motor não depende de drift — depende da port.

---

## 5. Outbox — `SyncOperation`

Tabela local durável. Uma linha por mutação pendente.

```dart
class SyncOperation {
  final String   id;              // UUID da operação (= idempotencyKey)
  final String   type;            // ex.: "VISIT_CHECK_IN" (registrado pelo app)
  final String   aggregateId;     // id do modelo de domínio afetado
  final String   payload;         // JSON (contrato do backend) — string
  final int?     baseVersion;     // serverVersion conhecido (detecção de conflito)
  final String?  dependsOn;       // id de outra SyncOperation que deve concluir antes
  final DateTime clientCreatedAt;
  final SyncOpStatus status;
  final int      attempts;
  final DateTime? nextRetryAt;    // backoff
  final String?  lastError;
  final DateTime? processedAt;
  final String?  ackResponse;     // corpo do ACK (serverVersion etc.)
}
```

`SyncOpStatus` (persistido por `.name`):

| Status | Significado | Terminal? |
|---|---|---|
| `pending` | na fila, aguardando drain | não |
| `sending` | enviada no batch atual (em voo) | não |
| `processed` | ACK de sucesso | sim (removível) |
| `skipped` | idempotência: já processada antes | sim (removível) |
| `conflict` | ACK de conflito (versão/estado) | sim → resolução |
| `failed` | erro transitório → retry com backoff | não (até esgotar) |
| `exhausted` | dead-letter: esgotou tentativas | sim → reenvio manual |
| `blocked` | dependência ainda não concluída | não (reavalia no próximo ciclo) |
| `rejected` | tipo não suportado pelo servidor | sim → erro de contrato |

**Invariantes:**
- `enqueue` só depois de `upsert` local bem-sucedido (nunca perde o dado do usuário se a fila falhar).
- `idempotencyKey == SyncOperation.id`, estável em todos os retries.
- Reenvio da mesma operação = mesma linha no servidor (idempotência).

---

## 6. Motor — `ArchbaseSyncEngine`

```dart
class ArchbaseSyncEngine {
  ArchbaseSyncEngine({
    required ArchbaseLocalStore store,
    required ArchbaseApiClient api,
    required ArchbaseConnectivityService connectivity,
    required ArchbaseBinaryUploader binaryUploader,
    required Map<String, SyncPayloadBuilder> builders, // registrados pelo app
    this.batchSize = 50,
    this.maxAttempts = 5,
  });

  /// Grava local (otimista) + enfileira a operação. Retorna o modelo salvo.
  Future<T> save<T extends ArchbaseSyncable>({
    required T model,
    required String type,
    String? dependsOn,
  });

  /// Marca soft-delete local + enfileira DELETE.
  Future<void> softDelete<T extends ArchbaseSyncable>(String id, {required String type});

  /// Drena a fila: batch → ACKs → reconciliação → gating de binários.
  Future<SyncCycleResult> drain();

  /// Recupera operações órfãs em `sending` (crash-recovery). Chamar no startup.
  Future<void> recoverStuck();

  /// Reenvio manual de uma operação em `exhausted`/`conflict`/`erro`.
  Future<void> retry(String operationId);

  /// Observa o estado agregado (para badges/contador).
  ValueListenable<ArchbaseSyncSnapshot> get status;
}
```

### 6.1 `drain()` — passos (determinístico)
1. **Lock** (um drain por vez; novo gatilho aguarda o mesmo).
2. **recoverStuck** (`sending` órfão → `pending`).
3. Selecionar `pending`/`failed` prontos (respeitando `nextRetryAt`), ordenar por `clientCreatedAt` e **topologia de `dependsOn`**.
4. Marcar `sending`; montar o lote (≤ `batchSize`) com os `payload` (via `builders[type]`).
5. `POST /sync/operations` (§7). **Não** propaga erro de rede — mantém `pending`.
6. Aplicar **ACK por operação**: `processed/skipped` → reconciliar entidade; `conflict/rejected` → `erro`; `failed` → backoff/`exhausted`; `blocked` → mantém.
7. **Gating de binários**: entidade com foto/assinatura pendente **não** vira `sincronizado`; sobe binários via `ArchbaseBinaryUploader` (multipart) e reavalia.
8. **Segundo drain** se binários geraram operações novas.
9. Atualizar `status` (snapshot) e liberar lock.

### 6.2 Gatilhos (sem timer periódico — bateria)
- App resume · reconexão · pull-to-refresh · comando remoto (gestão remota). Debounce curto para coalescer.

---

## 7. Protocolo de rede — batch `POST /api/v1/sync/operations`

**Request:**
```json
{
  "deviceId": "…",
  "atomic": false,
  "operations": [
    {
      "id": "uuid-op",
      "type": "VISIT_CHECK_IN",
      "aggregateId": "uuid-visita",
      "payload": { "...": "contrato do backend" },
      "baseVersion": 3,
      "dependsOn": null,
      "clientCreatedAt": "2026-07-26T09:00:00.000-03:00"
    }
  ]
}
```
- Header `X-App-Version` (compatibilidade → HTTP 426 se incompatível).
- `atomic=false` (default): processa o máximo possível; cada op tem seu ACK.

**Response (ACK por operação):**
```json
{
  "serverTime": "2026-07-26T12:00:00Z",
  "results": [
    { "id": "uuid-op", "status": "PROCESSED", "serverVersion": 4 },
    { "id": "uuid-op2", "status": "CONFLICT",
      "conflict": { "entityType": "Visita", "entityId": "…", "baseVersion": 3, "serverVersion": 5 } },
    { "id": "uuid-op3", "status": "SKIPPED" },
    { "id": "uuid-op4", "status": "BLOCKED", "dependsOn": "uuid-op" },
    { "id": "uuid-op5", "status": "REJECTED", "error": "tipo não suportado" },
    { "id": "uuid-op6", "status": "FAILED", "error": "…", "retryable": true }
  ],
  "counts": { "processed": 1, "skipped": 1, "conflict": 1, "blocked": 1, "rejected": 1, "failed": 1 }
}
```
- Status em UPPERCASE no fio; mapeados para `SyncOpStatus` no cliente.
- `counts` inclui **todos** os estados (inclusive `blocked`/`rejected`) — `success` nunca é `true` com op não resolvida. (Bug real da Tentativa B: `blocked`/`rejected` não contavam.)

---

## 8. Semântica travada (o núcleo do contrato)

### 8.1 Idempotência
- **Cliente:** `id` da operação estável em retries.
- **Servidor:** tabela `processed_sync_operation` com PK `(tenant_id, operation_id)` — sobrevive a restart e a semanas offline. Retenção 90d por _job_ agendado. Reenvio de op já processada → `SKIPPED` (não reexecuta).

### 8.2 Conflito (para **todas** as entidades sincronizáveis)
1. **Soft-delete vence (no resurrection):** se `deletedAt` no servidor, upsert atrasado → no-op, não ressuscita.
2. **Versão otimista:** se `baseVersion != serverVersion` → `CONFLICT` (com `serverVersion` atual no ACK) → app marca `erro`/oferece resolução.
3. **LWW estrito:** sem `baseVersion`, aplica só se `clientUpdatedAt` for **estritamente** mais novo; senão ACK `PROCESSED` sem aplicar (idempotente e sem sobrescrever).

### 8.3 Dependências
- `dependsOn` bloqueia de verdade: dependência não `processed`/`skipped` → dependente vira `BLOCKED` (não é enviado). Reavalia no próximo ciclo. (Não apenas "ordena".)

### 8.4 Dead-letter
- `failed` com `attempts >= maxAttempts` → `exhausted` (terminal). Aparece na tela de fila para **reenvio manual**; nunca some silenciosamente.

### 8.5 Binários (fotos/assinaturas)
- Binário no filesystem; no modelo, só o caminho. Upload multipart por `ArchbaseBinaryUploader` (canal separado do JSON, com retry).
- **Gating:** a entidade só atinge `sincronizado` quando **todos** os binários subiram. Enquanto pendente, permanece `pendente` mesmo com ACK `PROCESSED` do JSON.

### 8.6 Backoff
- Exponencial com teto + jitter 20%. `nextRetryAt` gravado; drain respeita.

### 8.7 Backend — transação por operação
- **Cada operação processa em transação própria (`REQUIRES_NEW`).** Uma falha/conflito **não** reverte as operações já aplicadas no mesmo lote. (Bug real da Tentativa B: lote inteiro em uma transação → primeiro conflito revertia tudo.)
- Registro em `processed_sync_operation` participa da transação da própria operação (commit atômico com o efeito).

---

## 9. Backend — contrato reusável (`archbase-java-boilerplate`)

```
POST /api/v1/sync/operations   → SyncOperationProcessor.process(batch)
```
- `SyncOperationProcessor` (base): loop, idempotência durável, dependências, transação-por-op (`REQUIRES_NEW`), montagem de ACK. **Genérico.**
- `SyncOperationHandler<T>` (por tipo, no app): `handle(payload) → serverVersion`; lança `ConflictException` (versão/estado) ou `SkippedException`.
- Migration base: `processed_sync_operation` (PK `(tenant_id, operation_id)`, status `PROCESSED|SKIPPED|CONFLICT`).
- Erros mapeados: `ConflictException → CONFLICT`, `SkippedException → SKIPPED`, tipo não registrado → `REJECTED`, demais → `FAILED (retryable)`. Handler HTTP para `VersionConflictException` (não cair em 500).

---

## 10. Feedback (widgets da lib)
- `ArchbaseSyncStatusBanner` (já existe) — só visual; o sync **não** depende dele.
- Badge por entidade (a partir de `syncStatus`) e contador global (a partir de `ArchbaseSyncSnapshot`).
- Tela de fila: lista operações (`type`, `aggregateId`, `attempts`, `lastError`) com remoção/reenvio manual.

---

## 11. Testes — o _gate_ (obrigatório antes de homologar)
Cobrir no motor (com `ArchbaseLocalStore` fake + `ArchbaseApiClient` mock):
1. **Idempotência:** 2× a mesma operação → 1 efeito; reenvio pós-`processed` → `skipped`.
2. **Conflito:** `baseVersion` divergente → `conflict` (não sobrescreve); LWW estrito ignora escrita antiga/igual.
3. **Erro parcial:** lote com 1 `failed`/`conflict` → as demais concluem (transação-por-op).
4. **Dependência:** `dependsOn` não concluída → dependente `blocked`; concluída → drena.
5. **Dead-letter:** `attempts >= max` → `exhausted`; `retry()` recoloca em `pending`.
6. **Crash-recovery:** `sending` órfão → `pending` no `recoverStuck`.
7. **Gating de binário:** JSON `processed` + foto pendente → entidade continua `pendente`; após upload → `sincronizado`.
8. **Serialização de enum por nome** (regressão do bug `.value`/`.name`).

Backend: testes de `SyncOperationProcessor` para idempotência, conflito, erro parcial (transação-por-op) e dependência.

---

## 12. Fronteira de migração do promotor (telas congeladas)
- **Referência de UI:** branch `main` do `vendax-promoter-app`. As telas **não** mudam.
- **Costura:** cada provider passa a ler de `ArchbaseOfflineRepository` e a escrever via `engine.save(...)`, mantendo a **mesma saída** para a tela.
- **Fatia a fatia:** um fluxo por vez (ex.: check-in → checklist → ruptura → temperatura → validade → concorrência → tarefas), homologado em device, aposentando o mecanismo antigo daquela fatia. Sem dualidade.
- **Rio Quality:** app novo direto na lib (valida o contrato limpo, sem legado).

---

## 13. Versionamento
- Novo módulo em `archbase_flutter` → bump **minor** (novos exports) e, quando substituir a `ArchbaseOfflineSyncQueue` atual, **major** com guia de migração no CHANGELOG.
- Contrato de rede versionado por `X-App-Version` + este documento (`Versão do contrato`).
