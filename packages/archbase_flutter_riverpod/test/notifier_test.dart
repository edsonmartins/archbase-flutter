import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:archbase_flutter_riverpod/archbase_flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterState extends ArchbaseControllerState {
  const _CounterState({this.count = 0, super.isLoading, super.error});

  final int count;

  @override
  _CounterState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? count,
  }) {
    return _CounterState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class _CounterNotifier extends ArchbaseRiverpodNotifier<_CounterState> {
  _CounterNotifier() : super(const _CounterState());

  Future<void> incrementAsync() => guard(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        state = state.copyWith(count: state.count + 1);
      });

  Future<void> fail() => guard(() async {
        throw ArchbaseAppError(message: 'kaboom');
      });
}

void main() {
  group('ArchbaseRiverpodNotifier', () {
    test('guard marca loading e desmarca em sucesso', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider =
          StateNotifierProvider<_CounterNotifier, _CounterState>(
              (_) => _CounterNotifier());

      final notifier = container.read(provider.notifier);
      final future = notifier.incrementAsync();
      expect(container.read(provider).isLoading, isTrue);
      await future;
      final state = container.read(provider);
      expect(state.isLoading, isFalse);
      expect(state.count, 1);
      expect(state.hasError, isFalse);
    });

    test('guard captura exception em state.error', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider =
          StateNotifierProvider<_CounterNotifier, _CounterState>(
              (_) => _CounterNotifier());

      await container.read(provider.notifier).fail();
      final state = container.read(provider);
      expect(state.hasError, isTrue);
      expect(state.error, 'kaboom');
      expect(state.isLoading, isFalse);
    });

    test('clearError limpa o erro sem mudar isLoading', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider =
          StateNotifierProvider<_CounterNotifier, _CounterState>(
              (_) => _CounterNotifier());

      await container.read(provider.notifier).fail();
      expect(container.read(provider).hasError, isTrue);
      container.read(provider.notifier).clearError();
      expect(container.read(provider).hasError, isFalse);
    });
  });
}
