import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/archbase_config.dart';
import '../../core/archbase_storage_keys.dart';
import '../../core/exceptions/api_exception.dart';
import '../../core/state/archbase_service.dart';
import '../../models/api_response.dart';
import '../../models/paginated_response.dart';
import '../storage/archbase_storage_service.dart';
import 'archbase_auth_interceptor.dart';
import 'archbase_error_interceptor.dart';
import 'archbase_logging_interceptor.dart';

class _BadCertOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// Cliente HTTP padrão da archbase. Encapsula [Dio] com:
/// - Auth interceptor (Bearer token + refresh em 401)
/// - Logging interceptor
/// - Error interceptor (mapeamento para [ApiException])
/// - Helpers tipados (`getJson`, `postJson`, `getList`, `getPaged`, `upload`)
///
/// Funções concretas de refresh ficam por conta do app: passe via
/// [setRefreshCallback] depois do bootstrap, junto com o `AuthService` real.
class ArchbaseApiClient extends ArchbaseService {
  ArchbaseApiClient({required this.config, required this.storage});

  ArchbaseConfig config;
  final ArchbaseStorageService storage;

  late Dio _dio;
  RefreshTokenCallback? _refresh;
  OnAuthFailure? _onAuthFailure;
  FutureOr<String?> Function()? _deviceIdProvider;

  Dio get raw => _dio;

  @override
  Future<void> onInit() async {
    if (config.acceptSelfSignedCerts) {
      HttpOverrides.global = _BadCertOverride();
    }
    _dio = _build(config);
  }

  /// Reconstrói o Dio (ex.: após troca de ambiente).
  Future<void> rebuild(ArchbaseConfig newConfig) async {
    config = newConfig;
    _dio = _build(newConfig);
    notifyListeners();
  }

  Dio _build(ArchbaseConfig cfg) {
    final dio = Dio(
      BaseOptions(
        baseUrl: cfg.baseUrl,
        connectTimeout: cfg.connectTimeout,
        receiveTimeout: cfg.receiveTimeout,
        sendTimeout: cfg.uploadTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...cfg.defaultHeaders,
        },
      ),
    );

    dio.interceptors.add(
      ArchbaseAuthInterceptor(
        storage: storage,
        publicPaths: cfg.publicPaths,
        tenantId: cfg.tenantId,
        deviceIdProvider: _deviceIdProvider ??
            () async => storage.read(ArchbaseStorageKeys.deviceId),
        appVersionProvider: () async =>
            (await storage.read(ArchbaseStorageKeys.appVersion)) ??
            cfg.appVersion,
        platformProvider: () async {
          if (kIsWeb) return 'web';
          return Platform.operatingSystem;
        },
        refresh: () async {
          final cb = _refresh;
          if (cb == null) {
            throw StateError(
              'ArchbaseApiClient sem refresh configurado. Use setRefreshCallback().',
            );
          }
          return cb();
        },
        onAuthFailure: () async => _onAuthFailure?.call(),
      ),
    );

    dio.interceptors.add(ArchbaseErrorInterceptor());
    if (cfg.loggingEnabled) {
      dio.interceptors.add(ArchbaseLoggingInterceptor());
    }
    return dio;
  }

  /// Configura o callback de refresh (chamado uma vez pelo AuthService).
  void setRefreshCallback({
    required RefreshTokenCallback refresh,
    OnAuthFailure? onAuthFailure,
  }) {
    _refresh = refresh;
    _onAuthFailure = onAuthFailure;
  }

  void setDeviceIdProvider(FutureOr<String?> Function()? provider) {
    _deviceIdProvider = provider;
  }

  // -----------------------------------------------------------------------
  // Helpers tipados — todos retornam ApiResponse<T> e nunca lançam.
  // -----------------------------------------------------------------------

  Future<ApiResponse<T>> getJson<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      (data) => fromJson(_asMap(data)),
    );
  }

  Future<ApiResponse<List<T>>> getList<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? envelopeKey,
  }) {
    return _request<List<T>>(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      (data) {
        final list = envelopeKey != null && data is Map
            ? data[envelopeKey] as List?
            : data as List?;
        return (list ?? const [])
            .whereType<Map>()
            .map((e) => fromJson(e.cast<String, dynamic>()))
            .toList();
      },
    );
  }

  Future<ApiResponse<PaginatedResponse<T>>> getPaged<T>(
    String path,
    T Function(Map<String, dynamic> json) fromItem, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<PaginatedResponse<T>>(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      (data) => PaginatedResponse<T>.fromJson(_asMap(data), fromItem),
    );
  }

  Future<ApiResponse<T>> postJson<T>(
    String path,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () => _dio.post(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      ),
      (data) => fromJson(_asMap(data)),
    );
  }

  Future<ApiResponse<T>> putJson<T>(
    String path,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic> json) fromJson, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<T>(
      () => _dio.put(
        path,
        data: body,
        queryParameters: queryParameters,
        options: options,
      ),
      (data) => fromJson(_asMap(data)),
    );
  }

  Future<ApiResponse<void>> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request<void>(
      () => _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      (_) {},
    );
  }

  /// Upload multipart. Use [progress] para barra de progresso.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required Map<String, dynamic> fields,
    required Map<String, ArchbaseUploadFile> files,
    required T Function(Map<String, dynamic> json) fromJson,
    void Function(int sent, int total)? progress,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      ...files.map(
        (k, f) => MapEntry(
          k,
          MultipartFile.fromBytes(f.bytes, filename: f.filename),
        ),
      ),
    });
    return _request<T>(
      () => _dio.post(
        path,
        data: formData,
        onSendProgress: progress,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: config.uploadTimeout,
          receiveTimeout: config.uploadTimeout,
        ),
      ),
      (data) => fromJson(_asMap(data)),
    );
  }

  // -----------------------------------------------------------------------

  Future<ApiResponse<T>> _request<T>(
    Future<Response> Function() call,
    T Function(dynamic data) fromData,
  ) async {
    try {
      final response = await call();
      return ApiResponse<T>.success(
        fromData(response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (err) {
      final api = err.error is ApiException
          ? err.error as ApiException
          : ApiException(
              message: err.message ?? 'Falha na requisição',
              statusCode: err.response?.statusCode,
              cause: err,
              stackTrace: err.stackTrace,
            );
      return ApiResponse<T>.error(
        api.message,
        statusCode: api.statusCode,
        fieldErrors: api.fieldErrors,
      );
    } catch (e, st) {
      _reportUnexpected(e, st);
      return ApiResponse<T>.error('Erro inesperado: $e');
    }
  }

  void _reportUnexpected(Object error, StackTrace st) {
    if (kDebugMode) {
      debugPrint('[archbase][api] erro inesperado: $error\n$st');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) return const {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return {'value': data};
  }
}

/// Arquivo a ser enviado em um upload multipart.
class ArchbaseUploadFile {
  ArchbaseUploadFile({required this.bytes, required this.filename});
  final Uint8List bytes;
  final String filename;
}
