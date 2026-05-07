# archbase_demo

App Flutter completo para validar (e demonstrar) os componentes da
[`archbase_flutter`](../README.md). Inspirado no padrão dos apps internos
(promotor de vendas / visitas a PDVs).

## O que ele faz

- **Login** com validação, dev users e credenciais.
- **Lista paginada** de visitas, com busca, refresh, empty/error/loading states.
- **CRUD completo**: criar, editar, excluir visitas com confirmação.
- **Offline-first**: enfileira mudanças quando rede está fora; sync banner
  reage ao estado da fila e da conexão.
- **Settings**: tema (system/light/dark), tamanho de fonte, alto contraste, logout.
- **Modo dev**: switch que simula offline (sem precisar matar Wi-Fi do
  device) — usado pelo flow Maestro de offline.

## Stack exercitada

| Componente | Uso no demo |
|---|---|
| `ArchbaseBootstrap` | bootstrap em `bootstrap/app_bootstrap.dart` |
| `ArchbaseApiClient` + `MockApiAdapter` | substitui Dio adapter por mock in-memory |
| `ArchbaseAuthService<U>` | `DemoAuthService` em `features/auth/` |
| `ArchbaseOfflineSyncQueue` | enfileira em `VisitaFormPage` quando offline |
| `ArchbaseConnectivityService` | controlado pelo toggle dev em settings |
| `ArchbaseCrudListScreen<T>` | `VisitasListPage` |
| `ArchbaseCrudFormScreen` | `VisitaFormPage` |
| `ArchbaseSettingsScreen` | `SettingsPage` (com `extraSections`) |
| `ArchbaseLoginScreen` | `LoginPage` |
| `ArchbaseSplashScreen` | `SplashPage` |
| `ArchbaseSyncStatusBanner` | dentro do `VisitasListPage` |
| `ArchbaseCard`, `ArchbaseDropdown`, `ArchbaseTextField` | nas telas |
| `ArchbaseValidators`, `ArchbaseDateFormatter`, `LabeledEnum` | em forms e cards |
| `ArchbaseThemeController` | persiste tema escolhido nas Settings |

## Rodar

```bash
cd demo
flutter pub get
flutter run
```

Sem device físico/emulador? Build de validação:

```bash
flutter test          # smoke + future widget tests
flutter analyze
```

## Credenciais (mock)

Qualquer email + qualquer senha com **4+ caracteres** loga.

Os dev users na própria tela:
- `promotor@archbase.dev` / `archbase`
- `admin@archbase.dev` / `archbase`

## Estrutura

```
lib/
├── main.dart
├── bootstrap/
│   └── app_bootstrap.dart       # init() centralizado
├── mock/
│   ├── mock_database.dart       # PDVs e visitas seedadas
│   └── mock_api_adapter.dart    # Dio adapter que serve /auth, /visitas
├── keys/
│   └── test_keys.dart           # IDs estáveis usados nos flows Maestro
└── features/
    ├── splash/
    ├── auth/
    │   ├── demo_auth_service.dart
    │   └── login_page.dart
    ├── home/                    # BottomNav com 3 abas
    ├── visitas/
    │   ├── models/{pdv.dart, visita.dart}
    │   ├── visitas_repository.dart
    │   ├── visitas_list_page.dart
    │   ├── visita_form_page.dart
    │   └── visitas_history_page.dart
    └── settings/
        └── settings_page.dart
```

## Testes E2E (Maestro)

Ver [`.maestro/README.md`](.maestro/README.md) para instalação e execução
dos flows. Os 4 flows cobrem: login, CRUD, offline e settings.
