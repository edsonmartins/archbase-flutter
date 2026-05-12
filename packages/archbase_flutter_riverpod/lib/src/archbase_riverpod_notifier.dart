import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Versão Riverpod de [ArchbaseController]. Use em vez de
/// `StateNotifier<TState>` para herdar o `guard()` que automatiza
/// loading + erro.
///
/// ```dart
/// class VisitasNotifier
///     extends ArchbaseRiverpodNotifier<VisitasState> {
///   VisitasNotifier(this._repo) : super(const VisitasState());
///   final VisitasRepository _repo;
///
///   Future<void> load() => guard(() async {
///     final visitas = await _repo.list();
///     state = state.copyWith(visitas: visitas);
///   });
/// }
///
/// final visitasProvider =
///     StateNotifierProvider<VisitasNotifier, VisitasState>(
///   (ref) => VisitasNotifier(ref.read(visitasRepoProvider)),
/// );
/// ```
abstract class ArchbaseRiverpodNotifier<TState extends ArchbaseControllerState>
    extends StateNotifier<TState> {
  ArchbaseRiverpodNotifier(super.state);

  /// Executa [action] limpando erro, marcando `isLoading=true`, e
  /// capturando exceptions em `state.error`. Devolve o valor ou null.
  Future<T?> guard<T>(
    Future<T> Function() action, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true) as TState;
    try {
      final result = await action();
      state = state.copyWith(isLoading: false) as TState;
      return result;
    } catch (error, stackTrace) {
      state = state.copyWith(
        isLoading: false,
        error: _humanize(error),
      ) as TState;
      onError?.call(error, stackTrace);
      return null;
    }
  }

  String _humanize(Object error) {
    if (error is ApiException) {
      if (error.hasFieldErrors) {
        return error.fieldErrors.map((e) => e.message).join('\n');
      }
      return error.message;
    }
    if (error is ArchbaseException) return error.message;
    return error.toString();
  }

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(clearError: true) as TState;
    }
  }
}
