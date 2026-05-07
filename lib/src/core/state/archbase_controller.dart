import 'dart:async';

import 'package:flutter/foundation.dart';

import '../exceptions/api_exception.dart';
import '../exceptions/archbase_exception.dart';

/// Estado base usado por [ArchbaseController]. Modela os 3 estados típicos
/// de uma operação assíncrona (loading, error, ready) sem amarrar a um
/// framework de state management.
@immutable
class ArchbaseControllerState {
  const ArchbaseControllerState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  bool get hasError => error != null;

  ArchbaseControllerState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ArchbaseControllerState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller base agnóstico de framework. Use diretamente como `ChangeNotifier`
/// (com Provider, ChangeNotifierProvider do Riverpod, GetX `Obx` via wrapper)
/// ou estenda para casos mais ricos.
abstract class ArchbaseController<TState extends ArchbaseControllerState>
    extends ChangeNotifier {
  ArchbaseController(this._state);

  TState _state;
  TState get state => _state;

  @protected
  set state(TState value) {
    _state = value;
    notifyListeners();
  }

  /// Executa [action] gerenciando loading e captura de erro automaticamente.
  ///
  /// Devolve o valor produzido ou `null` se houver falha. O erro fica
  /// disponível em `state.error` e é mapeado para mensagem amigável.
  @protected
  Future<T?> guard<T>(
    Future<T> Function() action, {
    String? loadingLabel,
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
