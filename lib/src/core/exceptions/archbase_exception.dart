/// Base de todas as exceções lançadas pela archbase_flutter.
abstract class ArchbaseException implements Exception {
  ArchbaseException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Erro genérico da camada de aplicação que carrega contexto exibível.
class ArchbaseAppError extends ArchbaseException {
  ArchbaseAppError({
    required String message,
    this.title,
    this.detail,
    this.context,
    this.code,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause: cause, stackTrace: stackTrace);

  final String? title;
  final String? detail;
  final String? context;
  final String? code;
}
