import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:archbase_flutter_getx/archbase_flutter_getx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterController extends ArchbaseGetController {
  final ValueNotifier<int> count = ValueNotifier<int>(0);

  Future<void> incrementAsync() => guard(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        count.value++;
      });

  Future<void> fail() => guard(() async {
        throw ArchbaseAppError(message: 'boom');
      });

  @override
  void onClose() {
    count.dispose();
    super.onClose();
  }
}

void main() {
  group('ArchbaseGetController', () {
    test('guard alterna isLoading e atualiza estado', () async {
      final ctrl = _CounterController();
      final future = ctrl.incrementAsync();
      expect(ctrl.isLoading.value, isTrue);
      await future;
      expect(ctrl.isLoading.value, isFalse);
      expect(ctrl.count.value, 1);
      expect(ctrl.hasError, isFalse);
      ctrl.onClose();
    });

    test('guard captura erro em error.value', () async {
      final ctrl = _CounterController();
      await ctrl.fail();
      expect(ctrl.hasError, isTrue);
      expect(ctrl.error.value, 'boom');
      expect(ctrl.isLoading.value, isFalse);
      ctrl.onClose();
    });

    test('clearError limpa erro', () async {
      final ctrl = _CounterController();
      await ctrl.fail();
      expect(ctrl.hasError, isTrue);
      ctrl.clearError();
      expect(ctrl.hasError, isFalse);
      ctrl.onClose();
    });
  });

  group('ValueListenable.asRx', () {
    test('Rx reflete mudanças do ValueNotifier', () {
      final source = ValueNotifier<int>(0);
      addTearDown(source.dispose);

      final bridge = source.asRx();
      expect(bridge.value, 0);

      source.value = 5;
      expect(bridge.value, 5);

      source.value = 10;
      expect(bridge.value, 10);

      bridge.disposeBridge();
    });

    test('disposeBridge remove listener e fecha Rx', () {
      final source = ValueNotifier<int>(0);
      addTearDown(source.dispose);

      final bridge = source.asRx();
      bridge.disposeBridge();

      // Mudar a source não deve quebrar nada (listener já removido).
      source.value = 99;
      // Não verificamos bridge.value porque o Rx está fechado.
    });
  });
}
