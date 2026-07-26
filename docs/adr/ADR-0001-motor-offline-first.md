# ADR-0001 — Motor Offline-First (Outbox) no `archbase_flutter`

- **Status:** Proposto
- **Data:** 2026-07-26
- **Decisor:** Edson Martins (conduzido por Claude); revalidação por Alexandre ao final
- **Escopo:** `archbase_flutter` (lib), apps consumidores (`vendax-promoter-app`, Vendedores Rio Quality e futuros), `archbase-java-boilerplate` (contrato de backend)
- **Substitui:** `vendax-promoter-app` ADR-0001 ("sync — camada REST com Brick") e a `ArchbaseOfflineSyncQueue` genérica atual (fila HTTP sobre Hive)

---

## 1. Contexto

O trabalho de campo (promotor no PDV, vendedor no cliente) acontece **onde o sinal é ruim ou inexistente**. O app precisa ser **offline-first**: o aparelho é a fonte de verdade da UI; a rede é um complemento assíncrono. Nada pode se perder nem duplicar.

Esse padrão **se repete em vários apps** da família Archbase (vendax-promoter, gestor-rq, de-olho-na-obra e, agora, Vendedores Rio Quality). Hoje cada app resolve por conta própria — e erra na mesma camada.

### 1.1 Duas tentativas, o mesmo teto

**Tentativa A — offline-first nativo do Brick** (`brick_offline_first_with_rest`): cada mutação virava `PUT /api/v1/sync/{recurso}/{id}` pela fila REST embutida do Brick.
- Validou os fluxos em device, mas bateu no teto do framework: o Brick **não dá callback de sucesso** → o status de sync era *inferido* varrendo a fila (frágil); **não distingue 2xx de 4xx** (foi preciso um `FailedMutationsStore` por fora); **sem suporte nativo** a batch, dependências entre operações, conflito tipado, dead-letter e crash-recovery. O cutover ficou incompleto (dualidade com Hive de leitura). Não fechou a homologação.

**Tentativa B — outbox customizado** (`SyncOperation` + batch `POST /sync/operations`): desenho de sync superior (estados explícitos, backoff, idempotência durável, ACKs).
- Melhor conceito, mas na prática ficou um **híbrido acidental**: o outbox passou a conviver com a fila nativa do Brick (a mesma entidade sincronizando por dois canais), com bug de transação no backend (um lote inteiro revertia ao primeiro conflito), conflito/merge só para uma entidade, **zero testes** no protocolo novo e a branch **sem compilar**.

### 1.2 A convergência que decide

Três implementações independentes — a Tentativa A (por gambiarra), a Tentativa B (por reescrita) e a **própria `archbase_flutter`** (que já tem `ArchbaseOfflineSyncQueue` + `SyncOperation`) — **convergiram para o padrão outbox**. Quando caminhos independentes chegam ao mesmo desenho, esse é o contrato que merece ser padronizado numa biblioteca.

O sinal técnico mais forte: **todos fugiram do mecanismo de REST nativo do Brick.** Brick como **store local** (SQLite, migrations, streams, cifrado) é ótimo; Brick como **motor de sync REST** não serve para um domínio com dependências, batch, conflito tipado e dead-letter.

### 1.3 Restrições do negócio

- **Não acumular dívida.** A manutenção e as features novas precisam ficar baratas. A dívida atual vem da **camada de dados bagunçada + dualidades**, não da UI.
- **Telas congeladas.** A UI homologada dos apps **não muda** — é o contrato de aceitação vivo. No `vendax-promoter-app`, a referência é a branch **`main`**.
- **Reuso entre projetos.** O motor precisa nascer genérico (dirigido por ≥2 casos de uso: promotor + Rio Quality).

---

## 2. Decisão

1. **O `archbase_flutter` passa a prover o motor offline-first como módulo de primeira classe** (`archbase_offline`), com contrato estável, testado e versionado. Os apps consomem; não reimplementam.

2. **Store local = `drift`** (SQLite tipado, reativo, cifrado via SQLCipher), **atrás de uma _port_** (`ArchbaseLocalStore`) para não amarrar os apps a um ORM específico.
   - **Brick é descontinuado** como motor de sync REST (revoga o ADR-0001 do promotor). Não usaremos "Brick só como SQLite" — usá-lo fora do seu fluxo de sync é remar contra o design dele.

3. **Sincronização = outbox único** (`SyncOperation`) drenado por **protocolo batch** `POST /api/v1/sync/operations` com **ACK por operação**. **Uma superfície só** — sem coexistir com PUT-por-recurso.

4. **Semântica travada no contrato** (os pontos onde as duas tentativas falharam):
   - **Idempotência durável** por `id` de cliente (UUID) + tabela no servidor (não só cache TTL).
   - **Conflito tipado**: LWW estrito por `clientUpdatedAt` **+** versão otimista, resultando em ACK `CONFLICT` (≠ `FAILED`), para **todas** as entidades — não só uma.
   - **Dependências** entre operações (`dependsOn`) com bloqueio real (`BLOCKED`), não apenas ordenação.
   - **Dead-letter** como estado terminal explícito (`EXHAUSTED`), separado de retry, com reenvio manual.
   - **Gating de binários**: a entidade só chega a `sincronizado` depois que suas fotos/assinaturas subiram (multipart em canal separado do JSON).
   - **Crash-recovery**: operações `SENDING` órfãs voltam a `PENDING` no startup.
   - **Transação por operação no backend** (`REQUIRES_NEW`): uma falha/conflito **não** reverte as operações já processadas no mesmo lote.

5. **Backend padronizado** no `archbase-java-boilerplate`: o endpoint batch + o processamento (idempotência/conflito/dependência/ACK) como **classes-base reusáveis**; cada API só registra os _handlers_ por tipo de operação.

6. **Fronteira lib × app** explícita: a lib provê motor + contrato + widgets de feedback; o app provê **models de domínio**, **payload builders** e **telas**. As telas permanecem intactas — a costura é o estado que os providers já expõem.

7. **Testes do protocolo são _gate_**: idempotência, conflito, erro parcial, dependência e crash-recovery cobertos por teste **antes** de qualquer homologação de app. Nenhuma das tentativas anteriores tinha isso.

8. **Zero código órfão (regra inegociável).** A confusão atual nasceu de **mecanismos convivendo** (Brick + Hive, outbox + fila nativa, `SyncCoordinator` morto). Regra: **cada fatia de migração remove o mecanismo antigo que substitui** — arquivos, dependências do `pubspec`, imports e telas transitórias — **antes** de ser dada como concluída. Nunca deixar dois caminhos para a mesma coisa "para limpar depois". Isso é verificado por **gate automatizado** (analyzer sem `unused_*`/`dead_code`; detecção de arquivos/código não usados; validador de dependências; e uma _ban-list_ de imports proibidos por fatia). Ver contrato §14.

---

## 3. Consequências

### Positivas
- **Um contrato, N apps.** O difícil (sync) é resolvido e testado uma vez; o app vira UI + domínio declarativo. Feature nova ≈ um model + um payload builder + a tela.
- **Fim das dualidades** — um motor, uma superfície, um sistema de status.
- **Aprendizado capitalizado** — vira código versionado, não conhecimento preso numa branch.
- **Telas preservadas** — risco de regressão de UX minimizado; a UI é o teste de aceitação.

### Negativas / custo
- Investimento inicial maior que "consertar um app": construir o módulo + backend base + testes.
- `drift` introduz codegen (build_runner) na lib e nos apps — mitigado por ser padrão de mercado, estável e sem a camada de sync opinativa do Brick.
- Apps que hoje usam a `ArchbaseOfflineSyncQueue` (Hive) precisarão migrar para o novo motor (quebra de contrato interno da lib → **minor/major** com CHANGELOG e guia).

### Riscos e mitigação
| Risco | Mitigação |
|---|---|
| Reescrever a camada de dados reintroduzir bugs | Telas congeladas (`main`) como contrato de aceitação + migração **fatia a fatia** homologada em device |
| Motor genérico "vazar" premissas de um app só | Dirigir o desenho por **dois** casos (promotor + Rio Quality) desde o ADR |
| Regressão do que já foi validado (idempotência/LWW/soft-delete/gestão remota) | Reaproveitar o que a Tentativa A/B **acertou** (endpoints, models, hidratação, painel admin) e cobrir com testes |
| Codegen (drift) atritar como o Brick atritou | Isolar o store atrás de `ArchbaseLocalStore`; drift não impõe protocolo de sync |
| Migração Flyway divergente entre ambientes | Contrato de backend com migrations lineares e idempotentes; sem scripts de "repair" ad-hoc |

---

## 4. Alternativas consideradas

1. **Manter o Brick nativo (Tentativa A) e só terminar o cutover do Hive.** Rejeitada: mantém o teto do Brick (reconciliação frágil, sem batch/dependências/conflito tipado) — exatamente o que travou a homologação.
2. **Consolidar o outbox da Tentativa B no app, sem lib.** Rejeitada: resolve um app e não capitaliza o reuso (Rio Quality e futuros repetiriam o esforço); além disso a branch atual está híbrida e sem testes.
3. **Evoluir a `ArchbaseOfflineSyncQueue` atual (fila HTTP genérica sobre Hive).** Rejeitada como base: é um replay de requests raso — sem store local relacional, sem idempotência/conflito/dependência/binário. Serve de inspiração, não de fundação.
4. **Brick "só como SQLite" + outbox custom.** Rejeitada: usar o Brick fora do seu fluxo de sync gera atrito de codegen sem os benefícios; `drift` entrega o store local de forma mais limpa.

---

## 5. Plano de adoção (resumo; detalhes no design)

1. **ADR + contrato do módulo** (este documento + `docs/design/archbase-offline-module.md`).
2. **Motor na lib com testes** (gate) — dirigido por promotor + Rio Quality.
3. **Backend base** no `archbase-java-boilerplate` (endpoint batch + processamento).
4. **Rio Quality** nasce direto na lib (app novo, sem legado — prova o contrato limpo).
5. **`vendax-promoter-app` migra por fatia**, **sem tocar nas telas** (`main` congelado): mapa da costura UI↔provider → reescrever o backing de cada provider sobre o motor → homologar em device → aposentar o mecanismo antigo daquela fatia.

Um dono do motor. Homologação contínua no device. Zero dualidade.

---

## 6. Referências

- `docs/design/archbase-offline-module.md` — contrato técnico do módulo.
- `vendax-promoter-app` `docs/spec/offline-first-promotor/` — RFC-0001/0002, ADR-0001/0002 (histórico das tentativas).
- Review de arquitetura (Tentativa B), 2026-07-25.
