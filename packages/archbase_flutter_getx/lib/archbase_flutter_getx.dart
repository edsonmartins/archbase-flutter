/// Adapter GetX para [archbase_flutter].
///
/// - [ArchbaseGetBindings] — registra os singletons no Get container
/// - [ArchbaseGetController] — base com `guard()` no estilo GetX
/// - `ValueListenable<T>.asRx()` — bridge para usar `ValueNotifier`s da
///   lib com `Obx`
library;

export 'src/archbase_get_bindings.dart';
export 'src/archbase_get_controller.dart';
export 'src/value_notifier_rx.dart';
