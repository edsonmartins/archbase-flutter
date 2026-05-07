import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/api/archbase_api_client.dart';
import '../services/auth/archbase_auth_service.dart';
import '../services/cache/archbase_cache_service.dart';
import '../services/connectivity/archbase_connectivity_service.dart';
import '../services/offline/archbase_offline_sync_queue.dart';
import '../services/storage/archbase_storage_service.dart';
import 'archbase_config.dart';
import 'archbase_env.dart';
import 'archbase_storage_keys.dart';

/// Ponto único de inicialização da biblioteca.
///
/// ```dart
/// await ArchbaseBootstrap.init(config: ArchbaseConfig(...));
/// ```
///
/// Após [init], os serviços ficam acessíveis via getters estáticos.
/// A biblioteca não impõe um container DI; apps com get_it/Riverpod podem
/// expor estes singletons da forma que preferirem.
class ArchbaseBootstrap {
  ArchbaseBootstrap._();

  static ArchbaseConfig? _config;
  static ArchbaseStorageService? _storage;
  static ArchbaseConnectivityService? _connectivity;
  static ArchbaseCacheService? _cache;
  static ArchbaseApiClient? _api;
  static ArchbaseOfflineSyncQueue? _syncQueue;
  static ArchbaseAuthService? _auth;

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static ArchbaseConfig get config {
    final c = _config;
    if (c == null) {
      throw StateError(
        'ArchbaseBootstrap não inicializado. Chame ArchbaseBootstrap.init().',
      );
    }
    return c;
  }

  static ArchbaseStorageService get storage => _ensure(_storage, 'storage');
  static ArchbaseConnectivityService get connectivity =>
      _ensure(_connectivity, 'connectivity');
  static ArchbaseCacheService get cache => _ensure(_cache, 'cache');
  static ArchbaseApiClient get api => _ensure(_api, 'api');
  static ArchbaseOfflineSyncQueue get syncQueue =>
      _ensure(_syncQueue, 'syncQueue');

  /// `auth` só fica disponível após [setAuthService] ser chamado pelo app.
  static ArchbaseAuthService? get auth => _auth;

  /// Inicializa a biblioteca. Chame antes de `runApp`.
  static Future<void> init({required ArchbaseConfig config}) async {
    if (_initialized) return;
    _config = config;

    await Hive.initFlutter();

    final storage = ArchbaseStorageService();
    await storage.init();
    _storage = storage;

    final connectivity = ArchbaseConnectivityService();
    await connectivity.init();
    _connectivity = connectivity;

    final cache = ArchbaseCacheService(defaultTtl: config.cacheTtl);
    await cache.init();
    _cache = cache;

    final api = ArchbaseApiClient(config: config, storage: storage);
    await api.init();
    _api = api;

    final syncQueue = ArchbaseOfflineSyncQueue(
      api: api,
      connectivity: connectivity,
      maxRetries: config.maxSyncRetries,
      backoffBase: config.syncBackoffBase,
      autoInterval: config.autoSyncInterval,
    );
    await syncQueue.init();
    _syncQueue = syncQueue;

    await _seedDeviceInfo(storage, config);

    _initialized = true;
  }

  /// Permite ao app injetar uma implementação concreta de
  /// [ArchbaseAuthService] após o bootstrap.
  static void setAuthService(ArchbaseAuthService auth) {
    _auth = auth;
  }

  /// Troca o ambiente em runtime (útil em tela de configuração de dev).
  static Future<void> switchEnvironment(ArchbaseEnv env) async {
    final current = config;
    if (current.currentEnv == env) return;
    _config = current.copyWith(currentEnv: env);
    await api.rebuild(_config!);
  }

  static Future<void> _seedDeviceInfo(
    ArchbaseStorageService storage,
    ArchbaseConfig config,
  ) async {
    if (await storage.read(ArchbaseStorageKeys.deviceId) == null) {
      // Geração lazy, sem amarrar package específico aqui.
      final id = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      await storage.write(ArchbaseStorageKeys.deviceId, id);
    }
    try {
      final pkg = await PackageInfo.fromPlatform();
      await storage.write(ArchbaseStorageKeys.appVersion, pkg.version);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Archbase] PackageInfo indisponível: $e');
      }
    }
  }

  static T _ensure<T>(T? value, String name) {
    if (value == null) {
      throw StateError(
        'ArchbaseBootstrap.$name acessado antes de init().',
      );
    }
    return value;
  }

  /// Apenas para testes — derruba o estado interno.
  @visibleForTesting
  static Future<void> reset() async {
    _api?.dispose();
    _syncQueue?.dispose();
    _connectivity?.dispose();
    _cache?.dispose();
    _config = null;
    _storage = null;
    _connectivity = null;
    _cache = null;
    _api = null;
    _syncQueue = null;
    _auth = null;
    _initialized = false;
  }
}
