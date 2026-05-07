import 'dart:async';
import 'dart:typed_data';

import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/hive_test_setup.dart';
import '../helpers/secure_storage_mock.dart';

class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter({this.failTimes = 0});

  int calls = 0;
  int failTimes;
  static const int _failStatus = 500;
  final List<String> seenPaths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    seenPaths.add(options.path);
    if (failTimes > 0) {
      failTimes--;
      return ResponseBody.fromString('{"error":"x"}', _failStatus, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });
    }
    return ResponseBody.fromString('{"ok":true}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initHiveForTests();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorage();
  });

  Future<(ArchbaseApiClient, _CountingAdapter, FakeConnectivity,
      ArchbaseStorageService)> setup({
    int failTimes = 0,
    String boxName = 'queue_test',
  }) async {
    final storage = ArchbaseStorageService();
    await storage.init();

    final api = ArchbaseApiClient(
      config: const ArchbaseConfig(
        appName: 'Test',
        currentEnv: ArchbaseEnv.dev,
        environments: {ArchbaseEnv.dev: 'http://test/'},
        autoSyncInterval: Duration(seconds: 30),
      ),
      storage: storage,
    );
    await api.init();

    final adapter = _CountingAdapter(failTimes: failTimes);
    api.raw.httpClientAdapter = adapter;
    api.setRefreshCallback(refresh: () async => 'fake-token');

    final connectivity = FakeConnectivity();

    return (api, adapter, connectivity, storage);
  }

  group('ArchbaseOfflineSyncQueue', () {
    test('enqueue + flush envia operação e remove da fila quando online',
        () async {
      final (api, adapter, conn, _) =
          await setup(boxName: 'queue_basic');
      final queue = ArchbaseOfflineSyncQueue(
        api: api,
        connectivity: conn,
        autoInterval: const Duration(hours: 1),
        boxName: 'queue_basic',
      );
      await queue.init();

      await queue.enqueue(
        method: SyncMethod.post,
        path: '/visitas',
        payload: {'pdv': 1},
      );
      expect(queue.pendingCount, 1);

      await queue.flush();
      expect(queue.pendingCount, 0);
      expect(adapter.calls, 1);
      expect(queue.status.value.lastSyncAt, isNotNull);

      await queue.clear();
      queue.dispose();
      api.dispose();
    });

    test('flush não envia quando offline', () async {
      final (api, adapter, conn, _) =
          await setup(boxName: 'queue_offline');
      conn.setOnline(false);
      final queue = ArchbaseOfflineSyncQueue(
        api: api,
        connectivity: conn,
        autoInterval: const Duration(hours: 1),
        boxName: 'queue_offline',
      );
      await queue.init();

      await queue.enqueue(method: SyncMethod.post, path: '/x', payload: {});
      await queue.flush();

      expect(adapter.calls, 0);
      expect(queue.pendingCount, 1);

      await queue.clear();
      queue.dispose();
      api.dispose();
    });

    test('falha incrementa retries e mantém na fila', () async {
      final (api, adapter, conn, _) =
          await setup(failTimes: 5, boxName: 'queue_retry');
      final queue = ArchbaseOfflineSyncQueue(
        api: api,
        connectivity: conn,
        backoffBase: const Duration(milliseconds: 1),
        autoInterval: const Duration(hours: 1),
        boxName: 'queue_retry',
      );
      await queue.init();

      await queue.enqueue(method: SyncMethod.post, path: '/x', payload: {});
      await queue.flush();
      expect(queue.pendingCount, 1);
      final ops = queue.peekAll();
      expect(ops.first.retries, 1);
      expect(ops.first.lastError, isNotNull);

      await queue.clear();
      queue.dispose();
      api.dispose();
    });

    test('reconexão dispara flush automático', () async {
      final (api, adapter, conn, _) =
          await setup(boxName: 'queue_reconnect');
      conn.setOnline(false);
      final queue = ArchbaseOfflineSyncQueue(
        api: api,
        connectivity: conn,
        autoInterval: const Duration(hours: 1),
        boxName: 'queue_reconnect',
      );
      await queue.init();

      await queue.enqueue(method: SyncMethod.post, path: '/x', payload: {});
      expect(adapter.calls, 0);

      conn.setOnline(true);
      // Drena loops async pendentes.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(adapter.calls, 1);
      expect(queue.pendingCount, 0);

      await queue.clear();
      queue.dispose();
      api.dispose();
    });

    test('status.pending atualiza com mudanças', () async {
      final (api, _, conn, _) = await setup(boxName: 'queue_status');
      conn.setOnline(false);
      final queue = ArchbaseOfflineSyncQueue(
        api: api,
        connectivity: conn,
        autoInterval: const Duration(hours: 1),
        boxName: 'queue_status',
      );
      await queue.init();

      expect(queue.status.value.pending, 0);
      await queue.enqueue(method: SyncMethod.post, path: '/a');
      expect(queue.status.value.pending, 1);
      await queue.enqueue(method: SyncMethod.put, path: '/b');
      expect(queue.status.value.pending, 2);

      await queue.clear();
      expect(queue.status.value.pending, 0);

      queue.dispose();
      api.dispose();
    });

    test('peekAll devolve operações ordenadas por createdAt', () async {
      final (api, _, conn, _) = await setup(boxName: 'queue_peek');
      conn.setOnline(false);
      final queue = ArchbaseOfflineSyncQueue(
        api: api,
        connectivity: conn,
        autoInterval: const Duration(hours: 1),
        boxName: 'queue_peek',
      );
      await queue.init();

      await queue.enqueue(method: SyncMethod.post, path: '/a');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await queue.enqueue(method: SyncMethod.post, path: '/b');

      final ops = queue.peekAll()..sort((x, y) => x.createdAt.compareTo(y.createdAt));
      expect(ops.first.path, '/a');
      expect(ops.last.path, '/b');

      await queue.clear();
      queue.dispose();
      api.dispose();
    });
  });
}
