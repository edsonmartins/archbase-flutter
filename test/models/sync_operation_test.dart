import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncOperation', () {
    test('toJson/fromJson é round-trip', () {
      final op = SyncOperation(
        id: 'abc',
        method: SyncMethod.post,
        path: '/visitas',
        payload: {'pdv': 1},
        headers: {'X-Tenant': 'a'},
        queryParams: {'force': true},
        tag: 'visita',
        retries: 2,
        lastError: 'timeout',
      );
      final json = op.toJson();
      final round = SyncOperation.fromJson(json);
      expect(round.id, 'abc');
      expect(round.method, SyncMethod.post);
      expect(round.path, '/visitas');
      expect(round.payload, {'pdv': 1});
      expect(round.headers, {'X-Tenant': 'a'});
      expect(round.queryParams, {'force': true});
      expect(round.tag, 'visita');
      expect(round.retries, 2);
      expect(round.lastError, 'timeout');
    });

    test('fromJson cai em SyncMethod.post quando method desconhecido', () {
      final op = SyncOperation.fromJson({
        'id': 'x',
        'method': 'XYZ',
        'path': '/foo',
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(op.method, SyncMethod.post);
    });

    test('fromJson tolera createdAt ausente', () {
      final op = SyncOperation.fromJson({
        'id': 'x',
        'method': 'put',
        'path': '/foo',
      });
      expect(op.method, SyncMethod.put);
      expect(op.createdAt, isA<DateTime>());
    });
  });
}
