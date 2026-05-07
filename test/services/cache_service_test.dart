import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initHiveForTests();
  });

  tearDownAll(() async {
    await closeHive();
  });

  Future<ArchbaseCacheService> newCache({
    Duration? ttl,
    String boxName = 'cache_test',
  }) async {
    final c = ArchbaseCacheService(defaultTtl: ttl, boxName: boxName);
    await c.init();
    return c;
  }

  group('ArchbaseCacheService', () {
    test('set + get retorna mesmo conteúdo', () async {
      final cache = await newCache(boxName: 'cache_basic');
      await cache.set('user', {'id': 1, 'nome': 'Edson'});
      final got =
          await cache.get<Map<String, dynamic>>('user', (raw) => Map.from(raw));
      expect(got, {'id': 1, 'nome': 'Edson'});
      await cache.clear();
    });

    test('get devolve null para chave inexistente', () async {
      final cache = await newCache(boxName: 'cache_missing');
      expect(await cache.get<String>('x', (raw) => raw.toString()), isNull);
    });

    test('TTL expira: set com ttl curto e get retorna null', () async {
      final cache = await newCache(boxName: 'cache_ttl');
      await cache.set(
        'k',
        {'v': 1},
        ttl: const Duration(milliseconds: 50),
      );
      expect(await cache.has('k'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(await cache.has('k'), isFalse);
      expect(await cache.get<Map<String, dynamic>>('k', (r) => Map.from(r)),
          isNull);
      await cache.clear();
    });

    test('getList desserializa lista de objetos', () async {
      final cache = await newCache(boxName: 'cache_list');
      await cache.set('items', [
        {'id': 1},
        {'id': 2},
        {'id': 3},
      ]);
      final got = await cache.getList<int>('items', (j) => j['id'] as int);
      expect(got, [1, 2, 3]);
      await cache.clear();
    });

    test('remove apaga apenas a chave', () async {
      final cache = await newCache(boxName: 'cache_remove');
      await cache.set('a', 1);
      await cache.set('b', 2);
      await cache.remove('a');
      expect(await cache.has('a'), isFalse);
      expect(await cache.has('b'), isTrue);
      await cache.clear();
    });

    test('aceita objetos com toJson', () async {
      final cache = await newCache(boxName: 'cache_dto');
      await cache.set('op', _OpDto('x', 9));
      final got =
          await cache.get<Map<String, dynamic>>('op', (r) => Map.from(r));
      expect(got, {'name': 'x', 'value': 9});
      await cache.clear();
    });
  });
}

class _OpDto {
  _OpDto(this.name, this.value);
  final String name;
  final int value;

  Map<String, dynamic> toJson() => {'name': name, 'value': value};
}
