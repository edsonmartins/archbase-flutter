import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonParse', () {
    test('integer aceita int, num, string', () {
      expect(JsonParse.integer(3), 3);
      expect(JsonParse.integer(3.7), 3);
      expect(JsonParse.integer('42'), 42);
      expect(JsonParse.integer('abc'), isNull);
      expect(JsonParse.integer(null), isNull);
    });

    test('decimal aceita ponto e vírgula', () {
      expect(JsonParse.decimal('1.5'), 1.5);
      expect(JsonParse.decimal('1,5'), 1.5);
      expect(JsonParse.decimal(2), 2.0);
      expect(JsonParse.decimal(null), isNull);
    });

    test('boolean aceita yes/no/sim/nao/0/1', () {
      expect(JsonParse.boolean('true'), isTrue);
      expect(JsonParse.boolean('SIM'), isTrue);
      expect(JsonParse.boolean('1'), isTrue);
      expect(JsonParse.boolean('não'), isFalse);
      expect(JsonParse.boolean('n'), isFalse);
      expect(JsonParse.boolean(0), isFalse);
      expect(JsonParse.boolean(true), isTrue);
      expect(JsonParse.boolean(null), isNull);
    });

    test('date aceita ISO, timestamp e DateTime', () {
      final iso = JsonParse.date('2026-05-07T10:30:00Z');
      expect(iso?.year, 2026);

      final ts = JsonParse.date(1700000000000);
      expect(ts, isNotNull);

      final dt = DateTime(2025, 1, 1);
      expect(JsonParse.date(dt), dt);

      expect(JsonParse.date(''), isNull);
      expect(JsonParse.date(null), isNull);
    });

    test('list filtra Maps e usa fromJson', () {
      final result = JsonParse.list(
        [
          {'id': 1},
          'ignorado',
          {'id': 2},
          null,
        ],
        (j) => j['id'] as int,
      );
      expect(result, [1, 2]);
    });

    test('list devolve const [] para entrada inválida', () {
      expect(JsonParse.list('nope', (j) => j), isEmpty);
    });

    test('pick retorna primeiro valor não-nulo', () {
      final json = <String, dynamic>{'displayName': null, 'name': 'Edson'};
      expect(JsonParse.pick(json, ['displayName', 'name']), 'Edson');
      expect(JsonParse.pick(json, ['ausente']), isNull);
    });

    test('stringList converte qualquer item para String', () {
      expect(JsonParse.stringList([1, 'dois', true]), ['1', 'dois', 'true']);
      expect(JsonParse.stringList(null), isEmpty);
    });
  });
}
