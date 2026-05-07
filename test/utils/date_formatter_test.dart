import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('ArchbaseDateFormatter.relative', () {
    final reference = DateTime(2026, 5, 7, 14, 30);

    test('hoje', () {
      final v = ArchbaseDateFormatter.relative(
        DateTime(2026, 5, 7, 9, 15),
        now: reference,
      );
      expect(v, startsWith('Hoje'));
    });

    test('ontem', () {
      final v = ArchbaseDateFormatter.relative(
        DateTime(2026, 5, 6, 9, 15),
        now: reference,
      );
      expect(v, startsWith('Ontem'));
    });

    test('há N dias (N entre 2 e 6)', () {
      final v = ArchbaseDateFormatter.relative(
        DateTime(2026, 5, 4, 0, 0),
        now: reference,
      );
      expect(v, contains('Há 3 dias'));
    });

    test('amanhã', () {
      final v = ArchbaseDateFormatter.relative(
        DateTime(2026, 5, 8, 9, 0),
        now: reference,
      );
      expect(v, startsWith('Amanhã'));
    });

    test('mais antigo cai em data formatada', () {
      final v = ArchbaseDateFormatter.relative(
        DateTime(2026, 1, 10),
        now: reference,
      );
      expect(v, '10/01/2026');
    });
  });

  group('ArchbaseDateFormatter.duration', () {
    test('mm:ss para menos de 1h', () {
      expect(
          ArchbaseDateFormatter.duration(const Duration(seconds: 75)), '01:15');
    });
    test('H:mm:ss para 1h+', () {
      expect(
        ArchbaseDateFormatter.duration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
    });
  });

  group('ArchbaseDateFormatter.date / dateTime', () {
    test('formata em pt-BR', () {
      final d = DateTime(2026, 5, 7, 14, 30);
      expect(ArchbaseDateFormatter.date(d), '07/05/2026');
      expect(ArchbaseDateFormatter.time(d), '14:30');
    });
  });
}
