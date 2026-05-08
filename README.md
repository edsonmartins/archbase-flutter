# Archbase Flutter

[![CI](https://github.com/edsonmartins/archbase-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/edsonmartins/archbase-flutter/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Framework Flutter da família **Archbase** (junto com `archbase-react` e o backend Java). Reúne os padrões que se repetiam nos apps internos (gestor-rq, de-olho-na-obra, vendax-promoter): client HTTP, autenticação, cache offline-first, geolocalização, push notifications, captura de mídia, theme system e widgets/templates de tela prontos.

## Princípios

- **Agnóstico de state management** — as classes base usam `ChangeNotifier` / `ValueNotifier` / `Stream` do próprio Flutter. Funciona com Riverpod, GetX, Provider ou Bloc sem amarração.
- **Offline-first** — `Hive` para cache, fila de sincronização com retry em backoff exponencial.
- **Brasileiro por padrão** — validadores de CPF/CNPJ, máscaras, formatadores de data/moeda em pt-BR.
- **Material 3 + responsivo** — theme light/dark com tokens semânticos, integração com `flutter_screenutil`.

## Instalação

```yaml
dependencies:
  archbase_flutter:
    path: ../archbase-flutter   # ou git/hosted depois
```

## Bootstrap

Em `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ArchbaseBootstrap.init(
    config: const ArchbaseConfig(
      appName: 'Meu App',
      appVersion: '1.0.0',
      currentEnv: ArchbaseEnv.dev,
      environments: {
        ArchbaseEnv.dev: 'https://api-dev.exemplo.com.br',
        ArchbaseEnv.homolog: 'https://api-homolog.exemplo.com.br',
        ArchbaseEnv.prod: 'https://api.exemplo.com.br',
      },
      tenantId: 'tenant-x',
    ),
  );

  // Plug do AuthService customizado:
  final auth = MeuAuthService(
    apiClient: ArchbaseBootstrap.api,
    tokens: ArchbaseTokenHolder(ArchbaseBootstrap.storage),
  );
  await auth.init();
  ArchbaseBootstrap.setAuthService(auth);

  runApp(const MyApp());
}
```

Após o `init`, ficam disponíveis (sem container DI):

- `ArchbaseBootstrap.api` — `ArchbaseApiClient` (Dio + interceptors)
- `ArchbaseBootstrap.storage` — `ArchbaseStorageService`
- `ArchbaseBootstrap.cache` — `ArchbaseCacheService` (Hive + TTL)
- `ArchbaseBootstrap.connectivity` — `ArchbaseConnectivityService`
- `ArchbaseBootstrap.syncQueue` — `ArchbaseOfflineSyncQueue`
- `ArchbaseBootstrap.auth` — o serviço de auth do app (depois de `setAuthService`)

## Mapa dos módulos

### `core/`
- `ArchbaseConfig`, `ArchbaseEnv`, `ArchbaseStorageKeys`
- Exceções: `ArchbaseException`, `ApiException` (com `fieldErrors`), `AuthException`
- Bases de state: `ArchbaseService` (substitui `init/dispose`), `ArchbaseController<TState>` (com `guard()` que cuida de loading/erro)

### `models/`
- `ApiResponse<T>` — wrapper success/error com `orThrow`, `map`
- `PaginatedResponse<T>` — compatível com Spring Data Pageable, com `appendPage`, `hasMore`
- `BaseDto`, `JsonParse` — parsing tolerante (datas em vários formatos, fallback de chaves)
- `LabeledEnum` mixin — enums com `(value, label, fromString)` em uma só declaração
- `SyncOperation`, `SyncMethod` — modelo da fila offline

### `services/`
- **api** — `ArchbaseApiClient` com `getJson`, `getList`, `getPaged`, `postJson`, `putJson`, `delete`, `upload`. Interceptors de auth (Bearer + refresh coordenado em 401), logging conciso, normalização de erros
- **auth** — `ArchbaseAuthService<U extends ArchbaseUser>` abstrata (você implementa `performLogin` e `performRefresh` — o resto está pronto). `SimpleArchbaseUser` para casos simples. `ArchbaseTokenHolder` para persistência segura
- **cache** — `ArchbaseCacheService` com TTL, purge automática
- **connectivity** — `ArchbaseConnectivityService` com `isConnected`, tipo de conexão, streams `onConnected/onDisconnected`
- **offline** — `ArchbaseOfflineSyncQueue` com retry, backoff, auto-sync por timer e ao reconectar
- **geolocation** — `ArchbaseGeolocationService` (posição, stream, geocoding reverso, geofence helper)
- **push** — `ArchbasePushNotificationService` (Firebase + flutter_local_notifications, canais, foreground/background)
- **media** — `ArchbaseImageService` (camera/galeria + compressão), `ArchbaseAudioRecorderService` (record + audioplayers)
- **storage** — `ArchbaseStorageService` (SharedPrefs + secure_storage unificados)

### `theme/`
- `ArchbaseColors` — paleta padrão (primary/status/charts/gradient)
- `ArchbaseTheme.light()` / `.dark()` — Material 3 ThemeData, suporte a alto contraste e escala de fonte
- `ArchbaseThemeController` — toggle system/light/dark + acessibilidade, persistido
- Extension `context.archbase` / `context.archbaseColors` / `context.isDarkMode`

### `utils/`
- `ArchbaseValidators` — `required`, `email`, `cpf`, `cnpj`, `cpfOrCnpj`, `phoneBr`, `strongPassword`, `confirm`, `compose`
- `ArchbaseDateFormatter` — `date`, `dateTime`, `time`, `relative` ("Hoje", "Ontem", "Há N dias"), `duration`
- `ArchbaseCurrencyFormatter` — `brl`, `brlCompact`, `decimal`, `percent`, `parseBrl`
- `ArchbasePhoneFormatter` + `ArchbaseMaskFormatter` (`phoneBr`, `cpf`, `cnpj`, `cep`, `dateBr`)
- `Debouncer`, `Throttler`, `JwtUtils`, `UuidUtils`, `ArchbaseResponsive`

### `widgets/`
- **feedback** — `ArchbaseLoading`, `ArchbaseInlineLoading`, `ArchbaseEmptyState`, `ArchbaseErrorView`, `ArchbaseShimmer`/`ArchbaseShimmerList`, `ArchbaseSyncStatusBanner`
- **forms** — `ArchbaseTextField`, `ArchbasePasswordField`, `ArchbaseButton` (4 variantes + loading), `ArchbaseDropdown.forEnum<E>()`, `ArchbaseSearchField` (com debounce), `ArchbaseNumericStepper`, `ArchbaseCountryPicker`
- **layout** — `ArchbaseAppBar`, `ArchbaseScaffold` (banner offline embutido), `ArchbaseSectionHeader`, `ArchbaseCard`, `ArchbaseDraggableHome` (header colapsável), `ArchbaseFloatingNavBar`
- **display** — `ArchbaseTextAvatar` + `ArchbaseAvatarStack`, `ArchbaseGlassContainer` (glass morphism), `ArchbaseCarousel`, `ArchbaseBadgeAdv`
- **structural** — `ArchbaseAccordion`, `ArchbaseStickyHeader`, `ArchbaseTimeline`, clippers (`Wave`, `Arc`, `Diagonal`, `ClippedHeader`)
- **dialogs** — `ArchbaseConfirmDialog.show()`, `ArchbaseAlertDialog.show()` (4 severidades), `ArchbaseBottomSheet.show()`, `ArchbaseToast`
- **media** — `ArchbaseAudioRecorderWidget`, `ArchbaseSignaturePad`, `ArchbasePhotoGallery`, `ArchbaseBarcodeScanner.open()`, `ArchbaseSwipeToConfirm`

### `screens/`
- `ArchbaseLoginScreen` — form com username/password, biometric opcional, dev users, lock por tentativas
- `ArchbaseSplashScreen` — bootstrap async + rota condicional
- `ArchbaseCrudListScreen<T>` — paginação infinita + busca + filtros + empty/error states
- `ArchbaseCrudFormScreen` — form com validação + confirmação de descarte + delete
- `ArchbaseDetailScreen` — abas ou seções verticais
- `ArchbaseSettingsScreen` — tema, fonte, alto contraste, biometria, logout
- `ArchbaseIntroScreen` — onboarding paginado com indicators

### `forms/` (sistema declarativo)
- `ArchbaseForm` + `ArchbaseFormController` — agrega valores e erros sem amarrar a state mgmt externo
- `ArchbaseFormTextField` — TextFormField integrado ao controller via `name:`
- Campos especializados: `ArchbaseFormCpfField`, `CnpjField`, `CnhField`, `PlateField`, `PhoneBrField`, `EmailField`, `CepField`, `BirthDateField`

## Exemplo mínimo

`example/` traz um app de "hello world" da lib (login + CRUD didático).

```bash
cd example
flutter create .          # gera as plataformas (1ª vez)
flutter pub get
flutter run
```

## App demo completo + E2E

`demo/` é um app completo de visitas/promotor que exercita ~80% dos
componentes (offline-first, sync queue, mock backend, theme controller)
e tem **4 flows Maestro** cobrindo login, CRUD, offline e settings.

```bash
cd demo
flutter pub get
flutter run

# em outra aba, rodar os flows E2E
maestro test demo/.maestro/
```

Detalhes: [`demo/README.md`](demo/README.md) e [`demo/.maestro/README.md`](demo/.maestro/README.md).

## Roadmap

- v0.2: helpers para Riverpod e GetX (adapters opcionais)
- v0.2: gráficos prontos (`ArchbaseLineChart`, `ArchbasePieChart`)
- v0.3: i18n com fallback automático para pt-BR
- v0.3: testes de widget para todos os widgets públicos

## Licença

MIT
