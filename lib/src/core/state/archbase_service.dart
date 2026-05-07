import 'dart:async';

import 'package:flutter/foundation.dart';

/// Classe base para qualquer serviço da Archbase.
///
/// Não amarra a um framework de state management. Provê:
/// - ciclo de vida `init()` / `dispose()`
/// - flag `isReady`
/// - notificação via [ChangeNotifier] quando o estado interno muda
///
/// Para reatividade granular, use [ValueNotifier] ou [Stream] em campos.
abstract class ArchbaseService extends ChangeNotifier {
  bool _initialized = false;
  bool _disposed = false;

  bool get isReady => _initialized && !_disposed;
  bool get isDisposed => _disposed;

  /// Hook chamado uma única vez. Sobrescreva [onInit] em vez deste método.
  Future<void> init() async {
    if (_initialized) return;
    await onInit();
    _initialized = true;
    if (!_disposed) notifyListeners();
  }

  /// Implementação concreta da inicialização do serviço.
  @protected
  Future<void> onInit() async {}

  /// Hook chamado quando o serviço é descartado.
  @protected
  Future<void> onDispose() async {}

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // Best-effort para serviços que precisem de async cleanup.
    onDispose();
    super.dispose();
  }
}
