import 'package:archbase_flutter/archbase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArchbaseValidators.cnh', () {
    test('CNH válida passa', () {
      // CNH gerada com algoritmo correto.
      expect(ArchbaseValidators.cnh('02650306461'), isNull);
    });
    test('todos dígitos iguais reprova', () {
      expect(ArchbaseValidators.cnh('11111111111'), isNotNull);
    });
    test('comprimento errado reprova', () {
      expect(ArchbaseValidators.cnh('123'), isNotNull);
    });
    test('allowEmpty respeita vazio', () {
      expect(ArchbaseValidators.cnh('', allowEmpty: true), isNull);
    });
  });

  group('ArchbaseValidators.plateBr', () {
    test('placa antiga AAA-9999 passa', () {
      expect(ArchbaseValidators.plateBr('ABC-1234'), isNull);
      expect(ArchbaseValidators.plateBr('ABC1234'), isNull);
    });
    test('placa Mercosul AAA9A99 passa', () {
      expect(ArchbaseValidators.plateBr('ABC1D23'), isNull);
    });
    test('formatos inválidos reprovam', () {
      expect(ArchbaseValidators.plateBr('ABCD1234'), isNotNull);
      expect(ArchbaseValidators.plateBr('123-ABCD'), isNotNull);
      expect(ArchbaseValidators.plateBr('ABC-12'), isNotNull);
    });
    test('aceita lowercase via uppercase implícito', () {
      expect(ArchbaseValidators.plateBr('abc1234'), isNull);
    });
  });

  group('ArchbaseValidators.ageMin', () {
    test('idade mínima 18: 17 anos reprova', () {
      final birth = DateTime.now().subtract(const Duration(days: 17 * 365));
      final dateBr =
          '${birth.day.toString().padLeft(2, '0')}/${birth.month.toString().padLeft(2, '0')}/${birth.year}';
      expect(ArchbaseValidators.ageMin(18)(dateBr), isNotNull);
    });
    test('idade mínima 18: 25 anos passa', () {
      final birth = DateTime.now().subtract(const Duration(days: 25 * 365));
      final dateBr =
          '${birth.day.toString().padLeft(2, '0')}/${birth.month.toString().padLeft(2, '0')}/${birth.year}';
      expect(ArchbaseValidators.ageMin(18)(dateBr), isNull);
    });
    test('vazio passa', () {
      expect(ArchbaseValidators.ageMin(18)(''), isNull);
    });
    test('formato inválido reprova', () {
      expect(ArchbaseValidators.ageMin(18)('xpto'), isNotNull);
    });
  });

  group('ArchbaseValidators.url', () {
    test('http e https válidos passam', () {
      expect(ArchbaseValidators.url('http://archbase.dev'), isNull);
      expect(ArchbaseValidators.url('https://archbase.dev/path'), isNull);
    });
    test('falta scheme reprova', () {
      expect(ArchbaseValidators.url('archbase.dev'), isNotNull);
    });
    test('scheme não-http reprova', () {
      expect(ArchbaseValidators.url('ftp://x.com'), isNotNull);
    });
  });

  group('ArchbaseValidators.creditCard', () {
    test('Visa válido (Luhn) passa', () {
      expect(ArchbaseValidators.creditCard('4111111111111111'), isNull);
    });
    test('número inválido reprova', () {
      expect(ArchbaseValidators.creditCard('1111111111111111'), isNotNull);
    });
  });

  group('ArchbaseValidators.equal/notEqual/pattern/numericBetween', () {
    test('equal aceita igual', () {
      expect(ArchbaseValidators.equal('foo')('foo'), isNull);
      expect(ArchbaseValidators.equal('foo')('bar'), isNotNull);
    });
    test('notEqual rejeita igual', () {
      expect(ArchbaseValidators.notEqual('foo')('foo'), isNotNull);
      expect(ArchbaseValidators.notEqual('foo')('bar'), isNull);
    });
    test('pattern usa regex', () {
      final v = ArchbaseValidators.pattern(RegExp(r'^\d{4}$'));
      expect(v('1234'), isNull);
      expect(v('abc'), isNotNull);
      expect(v(''), isNull); // vazio não testa
    });
    test('numericBetween limita range', () {
      final v = ArchbaseValidators.numericBetween(1, 100);
      expect(v('50'), isNull);
      expect(v('0'), isNotNull);
      expect(v('101'), isNotNull);
      expect(v(''), isNull);
    });
  });
}
