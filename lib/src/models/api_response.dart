import '../core/exceptions/api_exception.dart';

/// Wrapper padronizado de resposta da API. Use o factory adequado para
/// produzir um sucesso/erro a partir do raw response.
class ApiResponse<T> {
  ApiResponse._({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.fieldErrors = const [],
    this.code,
    this.errorData,
  });

  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final List<ApiFieldError> fieldErrors;

  /// Código de erro de negócio devolvido pela API (ex.: `CHAVE_INVALIDA`),
  /// lido de `code` na raiz ou de `error.code`.
  final String? code;

  /// Corpo bruto da resposta de erro, para casos que precisam de mais detalhe.
  final Object? errorData;

  bool get isSuccess => success;
  bool get isError => !success;
  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse._(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(
    String message, {
    int? statusCode,
    List<ApiFieldError> fieldErrors = const [],
    String? code,
    Object? errorData,
  }) {
    return ApiResponse._(
      success: false,
      message: message,
      statusCode: statusCode,
      fieldErrors: fieldErrors,
      code: code,
      errorData: errorData,
    );
  }

  /// Retorna [data] se sucesso ou lança [ApiException] caso contrário.
  T orThrow() {
    if (isSuccess && data != null) return data as T;
    throw ApiException(
      message: message ?? 'Falha na operação',
      statusCode: statusCode,
      code: code,
      fieldErrors: fieldErrors,
      responseData: errorData,
    );
  }

  /// Mapeia o conteúdo bem-sucedido para outro tipo.
  ApiResponse<R> map<R>(R Function(T data) mapper) {
    if (isError || data == null) {
      return ApiResponse<R>.error(
        message ?? 'Erro desconhecido',
        statusCode: statusCode,
        fieldErrors: fieldErrors,
        code: code,
        errorData: errorData,
      );
    }
    return ApiResponse<R>.success(
      mapper(data as T),
      message: message,
      statusCode: statusCode,
    );
  }
}
