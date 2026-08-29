# Changelog

## 0.7.1 — compatibilidade Firebase 11

### Mudou
- `mobile_scanner` ^5.2.3 → ^6.0.0 (GoogleMLKit 7 / GoogleDataTransport 10, resolve conflito de pods com firebase_messaging 15.x)


## 0.7.0 — integridade de mutação (coalescência + escrita atômica)

### Adicionado
- **`ArchbaseSyncEngine.save(coalesce: true)`** — coalescência local por
  `(type, aggregateId)`, opt-in (default `false`). Desacopla a chave de
  coalescência (estável) do `operationId` (id de mutação, único por envio):
  - enquanto a op está pendente, uma nova edição do mesmo `(type, aggregateId)`
    **substitui o payload** da op ainda não enviada (preserva a posição na fila
    e reusa o id, que nunca saiu do device);
  - depois do ACK (op removida), a próxima edição vira uma op **nova com UUID**,
    então o servidor não a devolve como `SKIPPED` por reuso de id.
  - Elimina a perda silenciosa do anti-padrão de `operationId` estável
    `TYPE:aggregateId` (edições descartadas após o primeiro envio).
- **`ArchbaseAtomicWriteStore`** — capacidade OPCIONAL do store: grava a
  entidade otimista e a operação de outbox na **mesma transação**. O motor a
  usa quando o store implementa (o `ArchbaseSqfliteStore` implementa); senão,
  cai no modo sequencial. Evita o estado inconsistente (entidade pendente sem
  op, ou registro removido antes do delete entrar na fila) após um crash.

### Notas
- Tudo aditivo/opt-in: atualizar de 0.6.x não muda o comportamento de quem já
  usa o motor. Nenhuma migração de schema (a coalescência usa as colunas
  `type`/`aggregate_id` já existentes).
- Implementações próprias de `ArchbaseLocalStore` seguem válidas sem mudança;
  para ganhar a escrita atômica, basta também implementar
  `ArchbaseAtomicWriteStore`.

## 0.6.2 — coalescing anti-ghost + resgate de dead-letter

### Adicionado
- **Coalescing delete↔upsert (anti-ghost)** no motor:
  `ArchbaseSyncEngine.save(..., supersedeAggregate: true)` cancela todas as
  operações do mesmo agregado — abertas **e terminais** (`exhausted`/`rejected`/
  `conflict`) — antes de enfileirar a nova. Elimina o "registro que ressuscita":
  um DELETE não deixa para trás um UPSERT no dead-letter que seria recriado depois.
- **Resgate de dead-letter (opt-in)** via `maxRescuesPerOperation` (default `0` =
  desligado). Quando `> 0`, o `drain()` promove operações `exhausted` de volta a
  `pending` até este teto por operação — destrava a fila quando o erro terminal
  pode ter sido resolvido no servidor (ex.: a dependência voltou a existir), sem
  virar retry infinito. Contador em memória (por sessão). Também exposto como
  `ArchbaseSyncEngine.rescueExhausted()` para chamada manual.

### Notas
- Ambos são **aditivos e opt-in** (defaults preservam o comportamento anterior):
  atualizar de 0.6.1 não exige nenhuma mudança em quem já usa o motor.

## 0.6.1 — resiliência de sync

### Adicionado
- **Reconciliação por transação** no motor: `ArchbaseSyncEngine.reconcilePendentes()`
  pergunta ao servidor (via `ArchbaseSyncSender.queryStatus`) quais das operações
  ainda não confirmadas (pending/sending/failed/blocked/exhausted) já foram
  processadas e fecha essas — marca a entidade `sincronizado` e remove a op.
  Resolve o caso "o servidor deu commit mas o cliente perdeu o response"
  (inclusive ops que esgotaram o retry). Read-only, por transação individual.
- `ArchbaseSyncSender.queryStatus(operationIds)` + `ArchbaseSyncStatusResponse`
  (contrato do endpoint `POST /api/v1/sync/operations/status`).
- `ArchbaseSyncEngine.failedOperations()` — expõe as ops em erro terminal
  (conflict/exhausted/rejected) com `lastError`, para o app listar com o motivo.

### Notas
- Implementadores de `ArchbaseSyncSender` agora precisam do método `queryStatus`
  (mudança de contrato).

## 0.6.0 — motor offline-first (`archbase_offline`)

### Adicionado
- Módulo **offline-first** reutilizável em `lib/src/offline/` (barrel `archbase_offline.dart`):
  - `ArchbaseSyncEngine` — outbox + drain single-flight, backoff exponencial + jitter,
    `dependsOn` que BLOQUEIA, dead-letter (`exhausted`) com retry manual, gating de binário,
    snapshot reativo para badges e hook de reconciliação.
  - `ArchbaseSyncable` / `ArchbaseSyncState` — contrato de entidade sincronizável
    (id UUID cliente, syncState, clientUpdatedAt, serverVersion, deletedAt).
  - `ArchbaseSqfliteStore` (implementa `ArchbaseLocalStore`) — store local em single-table
    JSON + outbox, `watch<T>()` reativo, opener injetável para SQLCipher; registro por
    `ArchbaseEntityCodec` (sem codegen).
  - Protocolo em lote (`archbase_sync_protocol.dart`): `ArchbaseSyncSender` (porta),
    serialização de operações e parsing de ACKs (PROCESSED/SKIPPED/CONFLICT/BLOCKED/
    REJECTED/FAILED) — casa com `POST /api/v1/sync/operations` do `archbase-offline-sync`.
  - `ArchbaseBinaryUploader` (porta) para upload de binários em canal separado, com gating.
- ADR-0001 (motor offline-first) + design do contrato do módulo em `docs/`.

## 0.5.3 — corrige URL de docs

### Mudou
- `documentation:` no pubspec aponta para o URL real do site
  (`/archbase-flutter-docs/` — o repo de docs é separado da lib)
- Adapters (`_riverpod`, `_getx`) também atualizados — agora dependem
  de `archbase_flutter: ^0.5.3` e o documentation URL correto

## 0.5.2 — metadata para pub.dev

### Mudou
- `pubspec.yaml`: description trimada para 180 chars (limite recomendado
  pelo pana), adicionados `issue_tracker`, `documentation` e `topics`
  (`framework`, `ui`, `offline`, `material-design`, `scaffolding`)

### Adicionado
- Site oficial de documentação em
  https://edsonmartins.github.io/archbase-flutter-docs/ (Docusaurus 3 +
  pt-BR/en, repo: `archbase-flutter-docs`)

## 0.5.1 — iOS no Maestro Cloud

### Adicionado
- Job `cloud-ios` em `.github/workflows/maestro-cloud.yml`, rodando
  em `macos-latest`: build do `.app` para iOS Simulator (sem
  assinatura), zip e upload via `action-maestro-cloud`
- Os 4 flows agora usam `appId: ${APP_ID}` para servir Android e iOS
  (bundle id difere — iOS não permite `_`)
- Job Android antigo renomeado para `cloud-android` (clareza)
- Cada job passa o `APP_ID` certo via `env:` no action

### Mudou
- `demo/.maestro/config.yaml` e os 4 flows: `appId` parametrizado
- `demo/.maestro/README.md`: documenta `export APP_ID=...` para
  rodar localmente

### Roadmap restante
- Bricks Mason equivalentes ao CLI Dart (interativo) — opcional

## 0.5.0 — CLI generator

### Adicionado
- CLI Dart `archbase` (`bin/archbase.dart`), exposto via `executables:`
  e invocável por `dart run archbase_flutter:archbase`
- Comando `feature <nome>`: gera scaffold completo de uma feature CRUD
  (model + repository + controller + 3 telas), com nomes derivados em
  snake/Pascal/camel/human automaticamente
- Helpers `Casing` (snake, kebab, camel, pascal, human) reutilizáveis
- Suporte a `--root`, `--endpoint`, `--force`

### Dependências
- `args: ^2.5.0` (parser do CLI)
- `path: ^1.9.0` (manipulação de paths)

### Testes
- +12 testes (Casing + FeatureScaffold em diretório temp) → 296 totais

## 0.4.4 — Maestro Cloud no CI

### Adicionado
- Workflow `.github/workflows/maestro-cloud.yml` que constrói o APK do
  demo e roda os 4 flows Maestro em devices reais via Maestro Cloud.
- Triggers: `push` para `main` quando `demo/**` muda, e
  `workflow_dispatch` manual. Workflow separado do CI principal para
  isolar o custo (Maestro Cloud é pago por minuto).
- Gate em secret: se `MAESTRO_CLOUD_API_KEY` não estiver configurado,
  o job termina como "skipped" sem falhar (forks-friendly).
- Docs no `demo/.maestro/README.md` explicando como gerar a API key e
  adicionar o secret no GitHub.
- Badge do workflow no README principal.

## 0.4.3 — cobertura de media (parcial)

### Testes
- +6 testes para `ArchbaseSwipeToConfirm` (rendering, ícone, cor) e
  `ArchbaseSignaturePad` (placeholder, labels custom, confirmar vazio)
- Total: 278 → 284. Gestos de swipe complexos ficam por conta do E2E
  Maestro (`tester.drag` é frágil quando o GestureDetector se move junto)

## 0.4.2 — cobertura de screens

### Testes
- +29 testes nas screens templates: `ArchbaseIntroScreen`,
  `ArchbaseDetailScreen` (modo seções + modo abas),
  `ArchbaseCrudFormScreen` (validate, submit, delete, discard guard),
  `ArchbaseSettingsScreen` (theme toggle, contraste, logout),
  `ArchbaseSplashScreen` (bootstrap, onReady, onError, minimumDisplay)
- Total: 249 → 278 testes. Cobertura de screens públicas em 100%.

## 0.4.1 — cobertura de testes

### Testes
- +47 testes (dialogs, display, shimmer, dropdown, search, country
  picker, layout, sticky header, clippers) → 249 totais
- Cobertura de widgets públicos sobe para ~85% (ainda faltam apenas
  os widgets que dependem de plugins nativos — media/scanner/audio)

## 0.4.0 — charts + i18n

### Adicionado

**Charts** (wrappers opinados sobre `fl_chart`)
- `ArchbaseLineChart` — múltiplas séries, eixos auto, tooltip, legend
- `ArchbasePieChart` — slices nomeados, donut com center text, animação
- `ArchbaseBarChart` — barras agrupadas com labels de eixo X
- `ArchbaseAreaChart` — line com fill
- Compartilham `ArchbaseChartSeries`, `ArchbaseChartPoint`, `ArchbaseChartSlice` e `ArchbaseChartLegend`
- Cores automáticas da `ArchbaseColors.chartPalette` quando não informadas

**i18n**
- `ArchbaseLocalizations` (abstract) — bundle com todos os strings da lib (~80 chaves: validators, botões, dialogs, erros HTTP, login, settings, sync banner)
- `ArchbaseLocalizationsPtBr` — implementação default
- `ArchbaseLocalizationsEnUs` — implementação de referência
- `ArchbaseLocalizations.set(...)` para override global
- `ArchbaseLocalizationsScope` (InheritedWidget) para override por subárvore
- `ArchbaseLocalizations.of(context)` resolve scope → global
- Validators e `ArchbaseErrorInterceptor` agora consultam o bundle ativo

### Testes
- +16 testes (charts + i18n) → 202 totais

## 0.3.0 — state management adapters

Sub-pacotes opcionais em `packages/` para ergonomia em um state mgmt
específico. A lib mãe continua agnóstica.

### Adicionado

**`archbase_flutter_riverpod`** (`packages/archbase_flutter_riverpod/`)
- 7 providers para os singletons (`archbaseApiProvider`, etc.)
- 5 stream providers reativos (`archbaseIsAuthenticatedProvider`,
  `archbaseCurrentUserProvider`, `archbaseIsConnectedProvider`,
  `archbaseConnectionTypeProvider`, `archbaseSyncStatusProvider`)
- `ArchbaseRiverpodNotifier<TState>` — `StateNotifier` com `guard()`

**`archbase_flutter_getx`** (`packages/archbase_flutter_getx/`)
- `ArchbaseGetBindings` — registra services no Get container
- `ArchbaseGetController` — `GetxController` base com `guard()`
  (`RxBool isLoading`, `RxnString error`)
- Extension `ValueListenable<T>.asRx()` + `BridgedRx<T>` para usar
  os `ValueNotifier`s da lib com `Obx`

### CI
- 2 jobs novos: `adapter-riverpod`, `adapter-getx` (paralelos ao demo)

## 0.2.0 — anteros migration

Portagem de componentes selecionados da `anterosflutter` (lib antiga). Tudo
foi reescrito para Material 3, sem RxDart/Flare e mantendo o estilo
agnóstico de state management.

### Adicionado

**Validators**
- `cnh`, `plateBr`, `ageMin`, `url`, `creditCard`, `equal`, `notEqual`,
  `pattern`, `numericBetween`

**Formatters / máscaras**
- `ArchbaseMaskFormatter.cnh`, `creditCard`
- `ArchbasePlateFormatter` (uppercase + alphanumeric, 7 chars)

**Forms (sistema declarativo)**
- `ArchbaseForm` + `ArchbaseFormController` (gerencia valores e erros sem
  amarrar a state mgmt externo)
- `ArchbaseFormTextField` integrado ao controller via `name:`
- Campos especializados: `ArchbaseFormCpfField`, `CnpjField`, `CnhField`,
  `PlateField`, `PhoneBrField`, `EmailField`, `CepField`, `BirthDateField`

**Widgets — display**
- `ArchbaseTextAvatar` (iniciais com cor determinística por hash de texto)
- `ArchbaseAvatarStack` (avatares sobrepostos com `+N`)
- `ArchbaseGlassContainer` (glass morphism com BackdropFilter)
- `ArchbaseCarousel` (paginação, autoplay, loop infinito)
- `ArchbaseBadgeAdv` (badge posicional sobre um child)

**Widgets — layout**
- `ArchbaseDraggableHome` (header colapsável, sem RxDart)
- `ArchbaseFloatingNavBar` (bottom nav flutuante com label inline)

**Widgets — structural**
- `ArchbaseAccordion` (single ou multi-open)
- `ArchbaseStickyHeader` + `ArchbaseStickyHeaderDelegate`
- `ArchbaseTimeline` (vertical com pontos+linha)
- `ArchbaseClippers`: `WaveClipper`, `ArcClipper`, `DiagonalClipper`,
  `ArchbaseClippedHeader`

**Widgets — forms**
- `ArchbaseNumericStepper` (touch spin com -/+)
- `ArchbaseCountryPicker` (~28 países com bandeiras emoji e dial code)

**Screens**
- `ArchbaseIntroScreen` (onboarding paginado)

**Utils**
- `ArchbaseExtensions`: 30+ extensions úteis em String, num, DateTime,
  List, Iterable, Map, BuildContext

### Testes
- 186 testes passando (de 138 → 186, +48 novos)

### Não portado (decisão consciente)
- Wrappers de `flare_flutter` (deprecado)
- TabBar/ListTile/Drawer wrappers (Material atual cobre)
- Componentes que duplicam `flutter_colorpicker`, `cool_alert`
- `phone_number:0.12.0+2` (abandonado) — usar `libphonenumber_plus`
  ou similares se precisar

## 0.1.0 — initial

- Setup do pacote, theme system, services base (Api/Auth/Cache/Connectivity/Storage/OfflineSync/Geolocation/Push/Media)
- Widgets reutilizáveis (Loading, Empty, Input, Button, AppBar, AudioRecorder, SignaturePad, PhotoGallery, BarcodeScanner)
- Templates de tela (Login, Splash, Crud List/Form, Settings)
- Validadores brasileiros (CPF/CNPJ/telefone/email/senha) e formatadores
- Modelos: ApiResponse&lt;T&gt;, PaginatedResponse&lt;T&gt;, BaseDto
