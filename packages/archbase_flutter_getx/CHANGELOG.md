# Changelog

## 0.2.0 — primeira release no pub.dev

### Adicionado
- `ArchbaseGetBindings.register()` — registra todos os singletons do
  `ArchbaseBootstrap` no Get container (`Get.find<ArchbaseApiClient>()`,
  etc.)
- `ArchbaseGetController` — `GetxController` base com `guard()`,
  `RxBool isLoading` e `RxnString error`
- `BridgedRx<T>` extension — converte `ValueNotifier<T>` da lib em
  `Rx<T>` do Get para usar com `Obx`
- Helper `disposeBridge()` para liberar a subscription manualmente

### Mudou
- Depende de `archbase_flutter: ^0.5.2` (publicado no pub.dev)
- LICENSE MIT incluída no pacote

## 0.1.0 — initial (path-only)

Versão path-only no monorepo, antes do publish no pub.dev.
