import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('ArchbaseCurrencyFormatter', () {
    test('brl formata com separador brasileiro', () {
      final v = ArchbaseCurrencyFormatter.brl(1234.5);
      // O nbsp do intl é   entre R$ e o número.
      expect(v.contains('R\$'), isTrue);
      expect(v.contains('1.234,50'), isTrue);
    });

    test('decimal formata sem símbolo', () {
      final v = ArchbaseCurrencyFormatter.decimal(1234567);
      expect(v, '1.234.567');
    });

    test('percent formata fração', () {
      final v = ArchbaseCurrencyFormatter.percent(0.185);
      // Pode vir com nbsp; checa pelos componentes.
      expect(v.contains('18,5'), isTrue);
      expect(v.contains('%'), isTrue);
    });

    test('parseBrl converte string formatada para double', () {
      expect(ArchbaseCurrencyFormatter.parseBrl('R\$ 1.234,50'), 1234.5);
      expect(ArchbaseCurrencyFormatter.parseBrl('-2.000,00'), -2000.0);
      expect(ArchbaseCurrencyFormatter.parseBrl(null), isNull);
      expect(ArchbaseCurrencyFormatter.parseBrl('xyz'), isNull);
    });
  });
}
