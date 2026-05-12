# archbase_flutter_riverpod

Adapter Riverpod para a [`archbase_flutter`](../../README.md).

## O que tem aqui

### Providers globais (singletons do bootstrap)

```dart
import 'package:archbase_flutter_riverpod/archbase_flutter_riverpod.dart';

final api = ref.read(archbaseApiProvider);
final auth = ref.read(archbaseAuthProvider);          // nullable
final config = ref.read(archbaseConfigProvider);
final storage = ref.read(archbaseStorageProvider);
final cache = ref.read(archbaseCacheProvider);
final syncQueue = ref.read(archbaseSyncQueueProvider);
final connectivity = ref.read(archbaseConnectivityServiceProvider);
```

Os providers leem direto dos singletons inicializados por
`ArchbaseBootstrap.init(...)` — não recriam serviços.

### Streams reativos para os `ValueNotifier`s da lib

```dart
final isAuth = ref.watch(archbaseIsAuthenticatedProvider);   // AsyncValue<bool>
final user = ref.watch(archbaseCurrentUserProvider);         // AsyncValue<ArchbaseUser?>
final online = ref.watch(archbaseIsConnectedProvider);       // AsyncValue<bool>
final connType = ref.watch(archbaseConnectionTypeProvider);  // AsyncValue<ArchbaseConnectionType>
final syncStatus = ref.watch(archbaseSyncStatusProvider);    // AsyncValue<ArchbaseSyncStatus>
```

### `ArchbaseRiverpodNotifier<TState>`

Substitui `StateNotifier<TState>` quando você quer o `guard()` da
`ArchbaseController` (loading + error handling automático):

```dart
class VisitasNotifier extends ArchbaseRiverpodNotifier<VisitasState> {
  VisitasNotifier(this._repo) : super(const VisitasState());
  final VisitasRepository _repo;

  Future<void> load() => guard(() async {
    final visitas = await _repo.list();
    state = state.copyWith(visitas: visitas);
  });
}

final visitasProvider =
    StateNotifierProvider<VisitasNotifier, VisitasState>(
  (ref) => VisitasNotifier(ref.read(visitasRepoProvider)),
);
```

`TState` precisa estender `ArchbaseControllerState` para ter
`isLoading` e `error` no shape — e seu `copyWith` precisa aceitar
`clearError: true`.

## Setup

```yaml
dependencies:
  archbase_flutter:
    path: ../archbase-flutter
  archbase_flutter_riverpod:
    path: ../archbase-flutter/packages/archbase_flutter_riverpod
  flutter_riverpod: ^2.5.1
```

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ArchbaseBootstrap.init(config: ArchbaseConfig(...));
  // (configurar AuthService etc.)
  runApp(const ProviderScope(child: MyApp()));
}
```

## Por que adapter em vez de embutir Riverpod na lib mãe

A `archbase_flutter` é agnóstica de state mgmt por desenho — funciona
com Riverpod, GetX, Provider, Bloc ou nada. Este pacote opcional
adiciona ergonomia para quem escolheu Riverpod, sem forçar o resto.
