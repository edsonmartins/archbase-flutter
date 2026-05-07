import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/archbase_storage_keys.dart';
import '../../core/state/archbase_service.dart';
import '../../models/sync_operation.dart';
import '../api/archbase_api_client.dart';
import '../connectivity/archbase_connectivity_service.dart';
import 'archbase_sync_status.dart';

/// Fila durável (Hive) de operações pendentes para envio futuro à API.
///
/// - Cada operação tem retries com backoff exponencial.
/// - Auto-flush por timer e ao detectar reconexão.
/// - O estado agregado é exposto via [status] (`ValueNotifier`).
class ArchbaseOfflineSyncQueue extends ArchbaseService {
  ArchbaseOfflineSyncQueue({
    required this.api,
    required this.connectivity,
    this.maxRetries = 5,
    this.backoffBase = const Duration(seconds: 2),
    this.autoInterval = const Duration(seconds: 30),
    String? boxName,
  }) : _boxName = boxName ?? ArchbaseStorageKeys.syncQueueBox;

  final ArchbaseApiClient api;
  final ArchbaseConnectivityService connectivity;
  final int maxRetries;
  final Duration backoffBase;
  final Duration autoInterval;
  final String _boxName;
  final _uuid = const Uuid();

  late Box<Map> _box;
  StreamSubscription<void>? _connectedSub;
  Timer? _timer;
  Completer<void>? _flushing;

  final ValueNotifier<ArchbaseSyncStatus> status =
      ValueNotifier<ArchbaseSyncStatus>(const ArchbaseSyncStatus());

  @override
  Future<void> onInit() async {
    _box = await Hive.openBox<Map>(_boxName);
    _refreshStatus();
    _connectedSub = connectivity.onConnected.listen((_) => unawaited(flush()));
    _timer = Timer.periodic(autoInterval, (_) => unawaited(flush()));
  }

  /// Quantas operações estão pendentes.
  int get pendingCount => _box.length;

  Future<String> enqueue({
    required SyncMethod method,
    required String path,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParams,
    String? tag,
  }) async {
    final id = _uuid.v4();
    final op = SyncOperation(
      id: id,
      method: method,
      path: path,
      payload: payload,
      headers: headers,
      queryParams: queryParams,
      tag: tag,
    );
    await _box.put(id, op.toJson());
    _refreshStatus();
    if (connectivity.isConnected.value) {
      unawaited(flush());
    }
    return id;
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _refreshStatus();
  }

  Future<void> clear() async {
    await _box.clear();
    _refreshStatus();
  }

  List<SyncOperation> peekAll() {
    return _box.values
        .map((m) => SyncOperation.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  /// Tenta drenar a fila respeitando retries e backoff. Múltiplas chamadas
  /// concorrentes compartilham o mesmo flush em curso.
  Future<void> flush() {
    final inflight = _flushing;
    if (inflight != null) return inflight.future;
    if (!connectivity.isConnected.value) return Future.value();

    final completer = Completer<void>();
    _flushing = completer;
    _runFlush().whenComplete(() {
      _flushing = null;
      completer.complete();
    });
    return completer.future;
  }

  Future<void> _runFlush() async {
    status.value = status.value.copyWith(isSyncing: true);
    try {
      final ops = peekAll()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final op in ops) {
        if (op.retries >= maxRetries) continue;
        if (!_isReady(op)) continue;
        final ok = await _trySend(op);
        if (ok) {
          await remove(op.id);
        } else {
          op.retries += 1;
          op.lastTriedAt = DateTime.now();
          await _box.put(op.id, op.toJson());
        }
      }
      status.value = status.value.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
        clearError: true,
      );
    } catch (e) {
      status.value = status.value.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
    } finally {
      _refreshStatus();
    }
  }

  bool _isReady(SyncOperation op) {
    if (op.lastTriedAt == null || op.retries == 0) return true;
    final waitMs = backoffBase.inMilliseconds *
        math.pow(2, math.min(op.retries - 1, 6)).toInt();
    final next = op.lastTriedAt!.add(Duration(milliseconds: waitMs));
    return DateTime.now().isAfter(next);
  }

  Future<bool> _trySend(SyncOperation op) async {
    try {
      switch (op.method) {
        case SyncMethod.post:
          await api.raw.post(
            op.path,
            data: op.payload,
            queryParameters: op.queryParams,
            options: op.headers != null ? Options(headers: op.headers) : null,
          );
          break;
        case SyncMethod.put:
          await api.raw.put(
            op.path,
            data: op.payload,
            queryParameters: op.queryParams,
            options: op.headers != null ? Options(headers: op.headers) : null,
          );
          break;
        case SyncMethod.delete:
          await api.raw.delete(
            op.path,
            queryParameters: op.queryParams,
            options: op.headers != null ? Options(headers: op.headers) : null,
          );
          break;
        case SyncMethod.patch:
          await api.raw.patch(
            op.path,
            data: op.payload,
            queryParameters: op.queryParams,
            options: op.headers != null ? Options(headers: op.headers) : null,
          );
          break;
        case SyncMethod.get:
          await api.raw.get(
            op.path,
            queryParameters: op.queryParams,
            options: op.headers != null ? Options(headers: op.headers) : null,
          );
          break;
      }
      return true;
    } catch (e) {
      op.lastError = e.toString();
      return false;
    }
  }

  void _refreshStatus() {
    status.value = status.value.copyWith(pending: _box.length);
  }

  @override
  Future<void> onDispose() async {
    _timer?.cancel();
    await _connectedSub?.cancel();
    status.dispose();
  }
}
