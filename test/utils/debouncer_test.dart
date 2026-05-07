import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('agrupa chamadas dentro da janela', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));
      var calls = 0;
      debouncer.run(() => calls++);
      debouncer.run(() => calls++);
      debouncer.run(() => calls++);
      expect(calls, 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(calls, 1);
    });

    test('cancel evita execução', () async {
      final debouncer = Debouncer(delay: const Duration(milliseconds: 30));
      var called = false;
      debouncer.run(() => called = true);
      debouncer.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(called, isFalse);
    });
  });

  group('Throttler', () {
    test('executa primeira e bloqueia segunda dentro da janela', () async {
      final throttler = Throttler(window: const Duration(milliseconds: 50));
      var calls = 0;
      expect(throttler.tryRun(() => calls++), isTrue);
      expect(throttler.tryRun(() => calls++), isFalse);
      expect(calls, 1);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(throttler.tryRun(() => calls++), isTrue);
      expect(calls, 2);
    });
  });
}
