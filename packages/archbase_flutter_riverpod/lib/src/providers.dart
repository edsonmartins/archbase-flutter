import 'dart:async';

import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Providers para acessar os singletons do [ArchbaseBootstrap] via Riverpod.
///
/// Pré-requisito: chame `ArchbaseBootstrap.init(...)` ANTES de `runApp`,
/// e envolva o app com `ProviderScope`. Esses providers leem direto dos
/// singletons estáticos — não recriam serviços.

final archbaseConfigProvider = Provider<ArchbaseConfig>((_) {
  return ArchbaseBootstrap.config;
});

final archbaseStorageProvider = Provider<ArchbaseStorageService>((_) {
  return ArchbaseBootstrap.storage;
});

final archbaseCacheProvider = Provider<ArchbaseCacheService>((_) {
  return ArchbaseBootstrap.cache;
});

final archbaseApiProvider = Provider<ArchbaseApiClient>((_) {
  return ArchbaseBootstrap.api;
});

final archbaseConnectivityServiceProvider =
    Provider<ArchbaseConnectivityService>((_) {
  return ArchbaseBootstrap.connectivity;
});

final archbaseSyncQueueProvider = Provider<ArchbaseOfflineSyncQueue>((_) {
  return ArchbaseBootstrap.syncQueue;
});

/// O AuthService só fica disponível após [ArchbaseBootstrap.setAuthService].
/// Provider é nullable.
final archbaseAuthProvider =
    Provider<ArchbaseAuthService<ArchbaseUser>?>((_) {
  return ArchbaseBootstrap.auth;
});

/// `true` se o usuário está autenticado. Reativo via [ValueNotifier].
final archbaseIsAuthenticatedProvider = StreamProvider<bool>((ref) {
  final auth = ref.watch(archbaseAuthProvider);
  if (auth == null) return Stream.value(false);
  return _notifierStream<bool>(auth.isAuthenticated);
});

/// Usuário atual (ou null se deslogado). Reativo.
final archbaseCurrentUserProvider =
    StreamProvider<ArchbaseUser?>((ref) {
  final auth = ref.watch(archbaseAuthProvider);
  if (auth == null) return Stream.value(null);
  return _notifierStream<ArchbaseUser?>(auth.currentUser);
});

/// Status de conexão (`true` = online). Reativo.
final archbaseIsConnectedProvider = StreamProvider<bool>((ref) {
  final conn = ref.watch(archbaseConnectivityServiceProvider);
  return _notifierStream<bool>(conn.isConnected);
});

/// Tipo de conexão. Reativo.
final archbaseConnectionTypeProvider =
    StreamProvider<ArchbaseConnectionType>((ref) {
  final conn = ref.watch(archbaseConnectivityServiceProvider);
  return _notifierStream<ArchbaseConnectionType>(conn.connectionType);
});

/// Estado da fila de sincronização offline. Reativo.
final archbaseSyncStatusProvider = StreamProvider<ArchbaseSyncStatus>((ref) {
  final queue = ref.watch(archbaseSyncQueueProvider);
  return _notifierStream<ArchbaseSyncStatus>(queue.status);
});

/// Converte um [ValueListenable] em [Stream]. Emite o valor atual no
/// `listen()` e propaga cada mudança subsequente.
Stream<T> _notifierStream<T>(ValueListenable<T> notifier) {
  late StreamController<T> controller;
  void listener() => controller.add(notifier.value);
  controller = StreamController<T>(
    onListen: () {
      controller.add(notifier.value);
      notifier.addListener(listener);
    },
    onCancel: () {
      notifier.removeListener(listener);
    },
  );
  return controller.stream;
}
