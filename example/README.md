# archbase_flutter — example

App mínimo demonstrando os componentes da `archbase_flutter`.

## Setup

```bash
cd example
flutter create .         # gera as plataformas (android/, ios/, etc.) só na 1ª vez
flutter pub get
flutter run
```

## O que o exemplo cobre

- `ArchbaseBootstrap.init(...)` no `main`
- `ArchbaseLoginScreen` com biometric e dev users
- `ArchbaseCrudListScreen` com paginação infinita simulada
- `ArchbaseCrudFormScreen` com validadores brasileiros
- `ArchbaseSettingsScreen` (tema, fonte, alto contraste, logout)
- `ArchbaseSyncStatusBanner` no Scaffold
- Toda a galeria de widgets (Loading, Empty, Cards, AudioRecorder, SignaturePad, BarcodeScanner)
