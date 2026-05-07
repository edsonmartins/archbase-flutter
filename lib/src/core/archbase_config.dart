import 'package:flutter/foundation.dart';

import 'archbase_env.dart';

/// Configuração global da biblioteca, fornecida na chamada de
/// [ArchbaseBootstrap.init].
@immutable
class ArchbaseConfig {
  const ArchbaseConfig({
    required this.appName,
    required this.environments,
    required this.currentEnv,
    this.appVersion = '1.0.0',
    this.tenantId,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.uploadTimeout = const Duration(minutes: 10),
    this.defaultHeaders = const {},
    this.acceptSelfSignedCerts = false,
    this.loginEndpoint = '/auth/login',
    this.refreshEndpoint = '/auth/refresh',
    this.logoutEndpoint = '/auth/logout',
    this.publicPaths = const ['/auth/login', '/auth/refresh', '/auth/forgot'],
    this.cacheTtl = const Duration(minutes: 30),
    this.maxImageSizeBytes = 5 * 1024 * 1024,
    this.enableLogging,
    this.maxSyncRetries = 5,
    this.syncBackoffBase = const Duration(seconds: 2),
    this.autoSyncInterval = const Duration(seconds: 30),
  });

  final String appName;
  final String appVersion;

  /// URL base para cada ambiente (`dev`, `homolog`, `prod`).
  final Map<ArchbaseEnv, String> environments;

  /// Ambiente em uso. Pode ser alterado em runtime via
  /// [ArchbaseBootstrap.switchEnvironment].
  final ArchbaseEnv currentEnv;

  /// Identificador de tenant enviado no header `X-TENANT-ID`.
  final String? tenantId;

  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration uploadTimeout;

  final Map<String, String> defaultHeaders;

  /// Se verdadeiro, aceita certificados auto-assinados (use só em dev/homolog).
  final bool acceptSelfSignedCerts;

  final String loginEndpoint;
  final String refreshEndpoint;
  final String logoutEndpoint;

  /// Endpoints que não exigem token (não passam pelo refresh interceptor).
  final List<String> publicPaths;

  /// TTL padrão do cache.
  final Duration cacheTtl;

  /// Tamanho máximo aceito para uploads de imagem.
  final int maxImageSizeBytes;

  /// Liga/desliga o logging do Dio. `null` = liga em debug, desliga em release.
  final bool? enableLogging;

  /// Quantidade máxima de tentativas para uma operação na fila offline.
  final int maxSyncRetries;

  /// Backoff base — a tentativa N espera `base * pow(2, N-1)`.
  final Duration syncBackoffBase;

  /// Intervalo do timer interno que tenta esvaziar a fila offline.
  final Duration autoSyncInterval;

  String get baseUrl {
    final url = environments[currentEnv];
    if (url == null) {
      throw StateError(
        'ArchbaseConfig.environments não contém URL para $currentEnv',
      );
    }
    return url;
  }

  bool get loggingEnabled => enableLogging ?? kDebugMode;

  ArchbaseConfig copyWith({
    String? appName,
    String? appVersion,
    Map<ArchbaseEnv, String>? environments,
    ArchbaseEnv? currentEnv,
    String? tenantId,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? uploadTimeout,
    Map<String, String>? defaultHeaders,
    bool? acceptSelfSignedCerts,
    String? loginEndpoint,
    String? refreshEndpoint,
    String? logoutEndpoint,
    List<String>? publicPaths,
    Duration? cacheTtl,
    int? maxImageSizeBytes,
    bool? enableLogging,
    int? maxSyncRetries,
    Duration? syncBackoffBase,
    Duration? autoSyncInterval,
  }) {
    return ArchbaseConfig(
      appName: appName ?? this.appName,
      appVersion: appVersion ?? this.appVersion,
      environments: environments ?? this.environments,
      currentEnv: currentEnv ?? this.currentEnv,
      tenantId: tenantId ?? this.tenantId,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      uploadTimeout: uploadTimeout ?? this.uploadTimeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      acceptSelfSignedCerts:
          acceptSelfSignedCerts ?? this.acceptSelfSignedCerts,
      loginEndpoint: loginEndpoint ?? this.loginEndpoint,
      refreshEndpoint: refreshEndpoint ?? this.refreshEndpoint,
      logoutEndpoint: logoutEndpoint ?? this.logoutEndpoint,
      publicPaths: publicPaths ?? this.publicPaths,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      maxImageSizeBytes: maxImageSizeBytes ?? this.maxImageSizeBytes,
      enableLogging: enableLogging ?? this.enableLogging,
      maxSyncRetries: maxSyncRetries ?? this.maxSyncRetries,
      syncBackoffBase: syncBackoffBase ?? this.syncBackoffBase,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
    );
  }
}
