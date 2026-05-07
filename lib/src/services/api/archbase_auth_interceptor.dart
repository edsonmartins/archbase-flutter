import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/archbase_storage_keys.dart';
import '../storage/archbase_storage_service.dart';

/// Função que tenta renovar o token chamando o endpoint de refresh.
/// Deve devolver o novo `accessToken` ou lançar [Exception] em caso de falha.
typedef RefreshTokenCallback = Future<String> Function();

/// Função opcional disparada quando o refresh falha (logout).
typedef OnAuthFailure = Future<void> Function();

/// Anexa o `Bearer` token e tenta refresh automático em 401.
class ArchbaseAuthInterceptor extends Interceptor {
  ArchbaseAuthInterceptor({
    required this.storage,
    required this.refresh,
    required this.publicPaths,
    this.onAuthFailure,
    this.tenantId,
    this.deviceIdProvider,
    this.appVersionProvider,
    this.platformProvider,
  });

  final ArchbaseStorageService storage;
  final RefreshTokenCallback refresh;
  final OnAuthFailure? onAuthFailure;
  final List<String> publicPaths;
  final String? tenantId;

  final FutureOr<String?> Function()? deviceIdProvider;
  final FutureOr<String?> Function()? appVersionProvider;
  final FutureOr<String?> Function()? platformProvider;

  // Garante que múltiplos 401 paralelos resultem em UM único refresh.
  Completer<String>? _refreshing;

  bool _isPublic(String path) {
    return publicPaths.any((p) => path.contains(p));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final token = await storage.readSecure(ArchbaseStorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    if (tenantId != null) {
      options.headers.putIfAbsent('X-TENANT-ID', () => tenantId);
    }
    final deviceId = await _maybe(deviceIdProvider);
    if (deviceId != null) options.headers['X-Device-Id'] = deviceId;
    final appVersion = await _maybe(appVersionProvider);
    if (appVersion != null) options.headers['X-App-Version'] = appVersion;
    final platform = await _maybe(platformProvider);
    if (platform != null) options.headers['X-Platform'] = platform;

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthError = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.extra['__isRefresh'] == true;
    final hasRetried = err.requestOptions.extra['__retried'] == true;

    if (!isAuthError ||
        isRefreshCall ||
        hasRetried ||
        _isPublic(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    try {
      final newToken = await _coordinatedRefresh();
      final retryRequest = err.requestOptions.copyWith();
      retryRequest.headers['Authorization'] = 'Bearer $newToken';
      retryRequest.extra = {...retryRequest.extra, '__retried': true};

      final dio = Dio(BaseOptions(baseUrl: retryRequest.baseUrl));
      final response = await dio.fetch(retryRequest);
      handler.resolve(response);
    } catch (refreshError) {
      await onAuthFailure?.call();
      handler.next(err);
    }
  }

  Future<String> _coordinatedRefresh() {
    if (_refreshing != null) return _refreshing!.future;
    final completer = Completer<String>();
    _refreshing = completer;
    refresh().then((token) {
      completer.complete(token);
    }).catchError((Object e) {
      completer.completeError(e);
    }).whenComplete(() {
      _refreshing = null;
    });
    return completer.future;
  }

  Future<String?> _maybe(FutureOr<String?> Function()? provider) async {
    if (provider == null) return null;
    try {
      return await provider();
    } catch (_) {
      return null;
    }
  }
}
