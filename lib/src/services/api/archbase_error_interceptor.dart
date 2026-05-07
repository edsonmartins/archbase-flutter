import 'package:dio/dio.dart';

import '../../core/exceptions/api_exception.dart';

/// Converte [DioException] em [ApiException] padronizada.
class ArchbaseErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: _convert(err),
        message: err.message,
        stackTrace: err.stackTrace,
      ),
    );
  }

  ApiException _convert(DioException err) {
    final data = err.response?.data;
    final status = err.response?.statusCode;

    String message;
    String? code;
    String? path;
    List<ApiFieldError> fields = const [];

    if (data is Map) {
      message = (data['message'] ??
              data['error'] ??
              data['detail'] ??
              _defaultFor(status, err.type))
          .toString();
      code = data['code']?.toString();
      path = data['path']?.toString();
      final rawErrors =
          data['errors'] ?? data['fieldErrors'] ?? data['subErrors'];
      if (rawErrors is List) {
        fields = rawErrors
            .whereType<Map>()
            .map((e) => ApiFieldError.fromJson(e.cast<String, dynamic>()))
            .toList();
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else {
      message = _defaultFor(status, err.type);
    }

    return ApiException(
      message: message,
      statusCode: status,
      code: code,
      path: path,
      fieldErrors: fields,
      responseData: data,
      cause: err,
      stackTrace: err.stackTrace,
    );
  }

  String _defaultFor(int? status, DioExceptionType type) {
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return 'Tempo de conexão esgotado. Tente novamente.';
    }
    if (type == DioExceptionType.connectionError) {
      return 'Sem conexão com o servidor. Verifique sua internet.';
    }
    if (type == DioExceptionType.cancel) {
      return 'Requisição cancelada.';
    }
    switch (status) {
      case 400:
        return 'Requisição inválida.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Você não tem permissão para esta ação.';
      case 404:
        return 'Recurso não encontrado.';
      case 409:
        return 'Conflito com o estado atual do recurso.';
      case 422:
        return 'Dados inválidos.';
      case 500:
      case 502:
      case 503:
        return 'Falha no servidor. Tente novamente em instantes.';
      default:
        return 'Falha na operação${status != null ? ' (HTTP $status)' : ''}.';
    }
  }
}
