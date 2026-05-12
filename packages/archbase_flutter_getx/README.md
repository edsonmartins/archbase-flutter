# archbase_flutter_getx

Adapter GetX para a [`archbase_flutter`](../../README.md).

## O que tem aqui

### `ArchbaseGetBindings`

Registra os singletons do `ArchbaseBootstrap` no container do Get para
que controllers possam fazer `Get.find<T>()`:

```dart
GetMaterialApp(
  initialBinding: ArchbaseGetBindings(),
  getPages: [...],
);
```

Disponibiliza:
- `ArchbaseConfig`, `ArchbaseStorageService`, `ArchbaseCacheService`
- `ArchbaseApiClient`, `ArchbaseConnectivityService`
- `ArchbaseOfflineSyncQueue`, `ArchbaseAuthService` (se setado)

### `ArchbaseGetController`

`GetxController` base com `guard()` automatizando loading + erro:

```dart
class VisitasController extends ArchbaseGetController {
  final visitas = <Visita>[].obs;
  final _repo = Get.find<VisitasRepository>();

  Future<void> load() => guard(() async {
    visitas.assignAll(await _repo.list());
  });
}
```

Expõe:
- `isLoading: RxBool`
- `error: RxnString` + `hasError`
- `guard<T>(action)` — captura exceptions e mapeia para mensagem amigável
- `clearError()`

### `ValueListenable<T>.asRx()`

Bridge para usar `ValueNotifier`s dos services da lib com `Obx`:

```dart
class HomeController extends ArchbaseGetController {
  late final isOnline =
      Get.find<ArchbaseConnectivityService>().isConnected.asRx();

  @override
  void onClose() {
    isOnline.disposeBridge();
    super.onClose();
  }
}

// No widget:
Obx(() => Text(controller.isOnline.value ? 'online' : 'offline'));
```

Lembre de chamar `disposeBridge()` no `onClose` do controller para
evitar listener pendurado.

## Setup

```yaml
dependencies:
  archbase_flutter:
    path: ../archbase-flutter
  archbase_flutter_getx:
    path: ../archbase-flutter/packages/archbase_flutter_getx
  get: ^4.6.6
```

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ArchbaseBootstrap.init(config: ArchbaseConfig(...));
  // (configurar AuthService etc.)
  runApp(GetMaterialApp(
    initialBinding: ArchbaseGetBindings(),
    home: const HomePage(),
  ));
}
```

## Por que adapter em vez de embutir GetX na lib mãe

A `archbase_flutter` é agnóstica de state mgmt por desenho. Esse pacote
opcional dá ergonomia para quem escolheu GetX, sem forçar o resto.
