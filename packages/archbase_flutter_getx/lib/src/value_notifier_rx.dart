import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Adapter que torna um [ValueListenable] reativo no padrão GetX.
///
/// Os services da `archbase_flutter` expõem `ValueNotifier<T>` para
/// estado (ex.: `connectivity.isConnected`, `auth.currentUser`). Em
/// vez de usar `ValueListenableBuilder`, embrulhe com `asRx()` e use
/// com `Obx`:
///
/// ```dart
/// class HomeController extends ArchbaseGetController {
///   late final isOnline = ArchbaseBootstrap.connectivity
///       .isConnected.asRx();
///
///   @override
///   void onClose() {
///     isOnline.disposeBridge();
///     super.onClose();
///   }
/// }
///
/// // Em widget:
/// Obx(() => Text(controller.isOnline.value ? 'online' : 'offline'));
/// ```
///
/// Chame [BridgedRx.disposeBridge] no `onClose` para evitar listener
/// pendurado no [ValueListenable].
extension ArchbaseValueListenableX<T> on ValueListenable<T> {
  BridgedRx<T> asRx() => BridgedRx<T>(this);
}

/// `Rx<T>` que segue um [ValueListenable] enquanto estiver vivo. Chame
/// [disposeBridge] quando não precisar mais.
class BridgedRx<T> {
  BridgedRx(this._source) : _rx = _source.value.obs {
    _listener = () => _rx.value = _source.value;
    _source.addListener(_listener);
  }

  final ValueListenable<T> _source;
  final Rx<T> _rx;
  late final VoidCallback _listener;
  bool _disposed = false;

  T get value => _rx.value;

  /// Acesso ao `Rx` interno (uso com `Obx`).
  Rx<T> get rx => _rx;

  void disposeBridge() {
    if (_disposed) return;
    _disposed = true;
    _source.removeListener(_listener);
    _rx.close();
  }
}
