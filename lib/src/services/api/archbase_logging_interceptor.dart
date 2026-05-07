import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logger conciso para Dio. Evita despejar bodies grandes em produção.
class ArchbaseLoggingInterceptor extends Interceptor {
  ArchbaseLoggingInterceptor({this.enabled = true, this.maxBodyChars = 800});

  final bool enabled;
  final int maxBodyChars;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      debugPrint(
        '[archbase] → ${options.method} ${options.uri} '
        '${_briefBody(options.data)}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      debugPrint(
        '[archbase] ← ${response.statusCode} ${response.requestOptions.uri} '
        '${_briefBody(response.data)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      debugPrint(
        '[archbase] ✕ ${err.response?.statusCode ?? '?'} '
        '${err.requestOptions.uri} ${err.message}',
      );
    }
    handler.next(err);
  }

  String _briefBody(dynamic body) {
    if (body == null) return '';
    final s = body.toString();
    if (s.length <= maxBodyChars) return s;
    return '${s.substring(0, maxBodyChars)}…(+${s.length - maxBodyChars})';
  }
}
