import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:get/get.dart';

/// Registra os singletons do [ArchbaseBootstrap] no container do Get.
///
/// Uso típico em `GetMaterialApp`:
/// ```dart
/// GetMaterialApp(
///   initialBinding: ArchbaseGetBindings(),
///   getPages: [...],
/// );
/// ```
///
/// Chame `ArchbaseBootstrap.init(...)` ANTES do `runApp` — este binding
/// apenas registra os singletons já inicializados; não cria nada.
class ArchbaseGetBindings extends Bindings {
  ArchbaseGetBindings({this.permanent = true});

  /// Se `true` (default), os services não são removidos quando uma rota
  /// que os usa sai da pilha. Mantém a instância viva pelo ciclo do app.
  final bool permanent;

  @override
  void dependencies() {
    if (!ArchbaseBootstrap.isInitialized) {
      throw StateError(
        'ArchbaseBootstrap não inicializado. Chame '
        'ArchbaseBootstrap.init(...) antes do runApp().',
      );
    }
    Get.put<ArchbaseConfig>(ArchbaseBootstrap.config, permanent: permanent);
    Get.put<ArchbaseStorageService>(ArchbaseBootstrap.storage,
        permanent: permanent);
    Get.put<ArchbaseCacheService>(ArchbaseBootstrap.cache,
        permanent: permanent);
    Get.put<ArchbaseApiClient>(ArchbaseBootstrap.api, permanent: permanent);
    Get.put<ArchbaseConnectivityService>(ArchbaseBootstrap.connectivity,
        permanent: permanent);
    Get.put<ArchbaseOfflineSyncQueue>(ArchbaseBootstrap.syncQueue,
        permanent: permanent);
    final auth = ArchbaseBootstrap.auth;
    if (auth != null) {
      Get.put<ArchbaseAuthService>(auth, permanent: permanent);
    }
  }
}
