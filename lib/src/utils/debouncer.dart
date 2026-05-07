import 'dart:async';

/// Debounce simples — útil para campos de busca, sliders, etc.
///
/// ```dart
/// final search = Debouncer(delay: const Duration(milliseconds: 300));
/// onChanged: (q) => search.run(() => controller.search(q));
/// ```
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}

/// Throttle — garante que a ação rode no máximo 1x por janela.
class Throttler {
  Throttler({this.window = const Duration(milliseconds: 500)});

  final Duration window;
  DateTime? _last;

  bool tryRun(void Function() action) {
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) >= window) {
      _last = now;
      action();
      return true;
    }
    return false;
  }

  void reset() => _last = null;
}
