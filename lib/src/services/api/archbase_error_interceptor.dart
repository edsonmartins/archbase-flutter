import 'package:dio/dio.dart';

import '../../core/exceptions/api_exception.dart';
import '../../i18n/archbase_localizations.dart';

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
      // Envelope aninhado {"error": {"code", "message", ...}} (BFFs/Archbase)
      // ou campos na raiz {"message", "code", ...} (Spring padrão).
      final nested = data['error'] is Map ? data['error'] as Map : null;
      final root = nested ?? data;
      message = (root['message'] ??
              (nested == null ? data['error'] : null) ??
              root['detail'] ??
              _defaultFor(status, err.type))
          .toString();
      code = root['code']?.toString();
      path = (root['path'] ?? data['path'])?.toString();
      final rawErrors = root['errors'] ??
          root['fieldErrors'] ??
          root['subErrors'] ??
          data['errors'] ??
          data['fieldErrors'] ??
          data['subErrors'];
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
    final l = ArchbaseLocalizations.current;
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return l.errorTimeout;
    }
    if (type == DioExceptionType.connectionError) {
      return l.errorConnection;
    }
    if (type == DioExceptionType.cancel) {
      return l.errorCancelled;
    }
    switch (status) {
      case 400:
        return l.errorBadRequest;
      case 401:
        return l.errorUnauthorized;
      case 403:
        return l.errorForbidden;
      case 404:
        return l.errorNotFound;
      case 409:
        return l.errorConflict;
      case 422:
        return l.errorValidation;
      case 500:
      case 502:
      case 503:
        return l.errorServer;
      default:
        return l.errorGeneric(status);
    }
  }
}
