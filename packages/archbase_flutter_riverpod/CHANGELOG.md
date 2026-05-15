# Changelog

## 0.2.0 — primeira release no pub.dev

### Adicionado
- Providers para os singletons do `ArchbaseBootstrap`:
  `archbaseApiProvider`, `archbaseAuthProvider`, `archbaseStorageProvider`,
  `archbaseCacheProvider`, `archbaseConnectivityProvider`,
  `archbaseSyncQueueProvider`, `archbaseConfigProvider`
- StreamProviders reativos sobre os `ValueNotifier`s da lib:
  `archbaseIsAuthenticatedProvider`, `archbaseCurrentUserProvider`,
  `archbaseIsConnectedProvider`, `archbaseConnectionTypeProvider`,
  `archbaseSyncStatusProvider`
- `ArchbaseRiverpodNotifier<TState>` — `StateNotifier` base com `guard()`

### Mudou
- Depende de `archbase_flutter: ^0.5.2` (publicado no pub.dev)
- LICENSE MIT incluída no pacote

## 0.1.0 — initial (path-only)

Versão path-only no monorepo, antes do publish no pub.dev.
