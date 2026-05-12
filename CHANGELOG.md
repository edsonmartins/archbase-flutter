# Changelog

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
