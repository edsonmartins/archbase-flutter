import 'archbase_exception.dart';

/// Erro de validação por campo, retornado tipicamente em respostas 400.
class ApiFieldError {
  ApiFieldError({required this.field, required this.message, this.code});

  final String field;
  final String message;
  final String? code;

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: (json['field'] ?? json['propertyPath'] ?? '').toString(),
      message: (json['message'] ?? json['detail'] ?? '').toString(),
      code: json['code']?.toString(),
    );
  }

  @override
  String toString() => '$field: $message';
}

/// Exceção para falhas na camada HTTP / API.
class ApiException extends ArchbaseException {
  ApiException({
    required String message,
    this.statusCode,
    this.code,
    this.path,
    this.fieldErrors = const [],
    this.responseData,
    super.cause,
    super.stackTrace,
  }) : super(message);

  final int? statusCode;
  final String? code;
  final String? path;
  final List<ApiFieldError> fieldErrors;
  final Object? responseData;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => (statusCode ?? 0) >= 500;
  bool get hasFieldErrors => fieldErrors.isNotEmpty;
}

/// Exceção lançada quando uma operação falha por falta de conexão.
class NetworkException extends ArchbaseException {
  NetworkException(super.message, {super.cause, super.stackTrace});
}

/// Exceção para timeouts.
class TimeoutException extends ArchbaseException {
  TimeoutException(super.message, {super.cause, super.stackTrace});
}
