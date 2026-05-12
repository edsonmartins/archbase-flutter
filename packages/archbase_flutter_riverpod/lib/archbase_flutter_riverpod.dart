/// Adapter Riverpod para [archbase_flutter].
///
/// Re-exporta os providers globais (auth, connectivity, sync, etc.) e
/// uma base [ArchbaseRiverpodNotifier] que herda o `guard()` do
/// [ArchbaseController].
library;

export 'src/providers.dart';
export 'src/archbase_riverpod_notifier.dart';
